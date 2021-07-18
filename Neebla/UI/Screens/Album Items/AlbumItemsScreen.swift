
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

// Gnarly memory leak when I was using `navigationBarItems`. Now using `toolbar`.
// See https://stackoverflow.com/questions/61303466

struct AlbumItemsScreen: View {
    let sharingGroupUUID: UUID
    let albumName: String
    
    init(album sharingGroupUUID: UUID, albumName: String) {
        self.sharingGroupUUID = sharingGroupUUID
        self.albumName = albumName
    }
    
    var body: some View {
        // Not using `iPadConditionalScreenBodySizer` here because we use the larger screen to show larger "icons". And on smaller screen, we just show smaller icons.
        AlbumItemsScreenBody(album: sharingGroupUUID, albumName: albumName)
            .background(Color.screenBackground)
    }
}

struct AlbumItemsScreenBody: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    let albumName: String

    init(album sharingGroupUUID: UUID, albumName: String) {
        self.viewModel = AlbumItemsViewModel(album: sharingGroupUUID)
        self.albumName = albumName
    }

    var body: some View {
        VStack {
            if viewModel.unfilteredNumberObjects == 0 {
                AlbumItemsScreenBodyEmptyState(viewModel: viewModel, albumName: albumName)
            }
            else {
                AlbumItemsScreenBodyWithContent(viewModel: viewModel, albumName: albumName)
            }
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                AlbumItemsScreenNavButtons(viewModel: viewModel)
            }
        }
        .sheetyDisplayer(item: $viewModel.sheetToShow, subscriber: alerty) { sheet in
            switch sheet {
            case .activityController:
                ActivityViewController(activityItems: viewModel.shareActivityItems())
                    .onAppear() {
                        // Switch out of changing mode, so when user comes back they don't have the selection state-- which doesn't seem right.
                        viewModel.changeMode = .none
                    }
            case .picker(let mediaPicker):
                mediaPicker.mediaPicker
                    .onDisappear() {
                        // Same idea as above. Note that if I do this with a .onTapGesture on the Menu, this causes the menu to disappear.
                        // If I trigger this from `onAppear`, I get other grief in my view hierarchy. A view lower in the hierarchy (`URLPickerViewModel`) stops responding to its published view model values.
                        viewModel.changeMode = .none
                    }
            case .moveItemsToAnotherAlbum:
                AlbumListModal(specifics: viewModel.moveItemsSpecifics)
            }
        }
        .onAppear() {
            viewModel.screenDisplayed = true
        }
        .onDisappear() {
            viewModel.screenDisplayed = false
        }
    }
}

struct AlbumItemsScreenBodyEmptyState: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    @StateObject var signInManager = Services.session.signInServices.manager

    let albumName: String

    init(viewModel:AlbumItemsViewModel, albumName: String) {
        self.viewModel = viewModel
        self.albumName = albumName
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("No media items found in album.")
            Image("client-icon")
            
            switch signInManager.userIsSignedIn {
            case .some(true):
                VStack {
                    Text("Do you just need to refresh?")
                    Button(
                        action: {
                            viewModel.sync(userTriggered: true)
                        },
                        label: {
                            SFSymbolIcon(symbol: .goforward)
                        }
                    )
                }
                
                VStack {
                    Text("Or perhaps you need to add some?")
                    MediaPickersMenu(viewModel: viewModel)
                }
                
            default:
                VStack {
                    Text("Please sign in to refresh or add media items.")
                }
            }
        }.padding(20)
        .navigationTitle(albumName)
    }
}

struct AlbumItemsScreenBodyWithContent: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    /* It seems hard to get the spacing to work out reasonably. At first, it looked OK on iPhone 11 but not on iPhone 8-- on iPhone 8 there was no spacing. In this case I was using:
    
        let gridItemLayout = [GridItem(.adaptive(minimum: 50), spacing: 20)]
      
      Just changing the `spacing` doesn't really help. What seems to be going on is that the LazyVGrid is trying to fit as many cells as it can per row. And if that means no spacing, then there is no spacing.
      
      What's helping is to use the image dimension as the minimum. This is looking OK on iPhone 8 and iPhone 11.
    */
    let gridItemLayout: [GridItem]
    
    @State var object: ServerObjectModel?
    let albumName: String
    let config: IconConfig

    init(viewModel:AlbumItemsViewModel, albumName: String) {
        self.viewModel = viewModel
        self.albumName = albumName
        
        config = UIDevice.isPad ? .large : .small
        
        gridItemLayout = [
            GridItem(.adaptive(minimum: config.dimension), spacing: 5)
        ]
    }
    
    var body: some View {
        VStack {            
            RefreshableScrollView(refreshing: $viewModel.loading) {
                LazyVGrid(columns: gridItemLayout) {
                    ForEach(viewModel.objects, id: \.fileGroupUUID) { item in
                        AlbumItemsScreenCell(object: item, viewModel: viewModel, config: config)
                            .onTapGesture {
                                switch viewModel.changeMode {
                                case .moving, .sharing, .moveAll:
                                    viewModel.toggleItemToChange(fileGroupUUID: item.fileGroupUUID)
                                case .none:
                                    object = item
                                    viewModel.showCellDetails = true
                                }
                            }
                            .onLongPressGesture {
                                viewModel.restartDownload(fileGroupUUID: item.fileGroupUUID)
                            }
                    } // end ForEach
                } // end LazyVGrid
            }.padding(5)
            // Mostly this is to animate updates from the menu. E.g., the sorting order.
            .animation(.easeInOut)
            
            // Had a problem with return animation for a while: https://stackoverflow.com/questions/65101561
            // The solution was to take the NavigationLink out of the scrollview/LazyVGrid above.
            if let object = object {
                // The `NavigationLink` works here because the `MenuNavBar` contains a `NavigationView`.
                NavigationLink(
                    destination:
                        ObjectDetailsView(object: object),
                    isActive:
                        $viewModel.showCellDetails) {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .disabled(true)
            } // end if
        }
        .sortyFilterMenu(title: albumName, sortFilterModel: viewModel.sortFilterSettings)
    }
}

struct MediaPickersMenu: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    let pickers:[MediaPicker]
    @StateObject var signInManager = Services.session.signInServices.manager
    
    init(viewModel:AlbumItemsViewModel) {
        self.viewModel = viewModel
        pickers = AnyPicker.pickers { assets in
            viewModel.uploadNewItem(assets: assets)
        }
    }
    
    var body: some View {
        VStack {
            // In some cases, the menu is presented with items in top to bottom order. In others, it's presented bottom to top. E.g., from the nav bar, the order is top to bottom. Presented from a button on the screen, I'm getting bottom to top order. Seems a context sensitive issue.
            // See https://stackoverflow.com/questions/65543824/swiftui-menu-top-to-bottom-order-varies-depending-on-context/65543825#65543825
            Menu {
                ForEach(pickers, id: \.mediaPickerUIDisplayName) { picker in
                    Button(action: {
                        viewModel.sheetToShow = .picker(picker)
                    }) {
                        Text(picker.mediaPickerUIDisplayName)
                    }.enabled(picker.mediaPickerEnabled)
                }
            } label: {
                SFSymbolIcon(symbol: .plusCircle)
            }
            .enabled(signInManager.userIsSignedIn == true)
        }
    }
}

private struct AlbumItemsScreenNavButtons: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    @Environment(\.colorScheme) var colorScheme
    @StateObject var signInManager = Services.session.signInServices.manager
    
    var body: some View {
        HStack(spacing: 0) {
            if viewModel.changeMode != .none &&
                viewModel.itemsToChange.count > 0 {
                Button(
                    action: {
                        switch viewModel.changeMode {
                        case .none:
                            logger.error("Should not get here!!")
                        case .moving, .moveAll:
                            viewModel.sheetToShow = .moveItemsToAnotherAlbum
                        case .sharing:
                            viewModel.sheetToShow = .activityController
                        }
                    },
                    label: {
                        SFSymbolIcon(symbol: .squareAndArrowUp)
                    }
                )

                Button(
                    action: {
                        viewModel.changeMode = .none
                        viewModel.itemsToChange.removeAll()
                    },
                    label: {
                        SFSymbolIcon(symbol: .xmark)
                    }
                )
            }
            else {
                MediaPickersMenu(viewModel: viewModel)
            
                Menu {
                    Button(action: {
                        viewModel.toggleSharingMode()
                    }) {
                        Label {
                            Text("Share items")
                        } icon: {
                            Image(colorScheme == .light ? "Share" : "ShareWhite")
                                .renderingMode(.template)
                        }
                    }.enabled(viewModel.objects.count > 0)

                    Button(action: {
                        viewModel.toggleMovingMode(moveAll: false)
                    }) {
                        Label("Move items", systemImage: "tray.and.arrow.up")
                    }.enabled(
                        viewModel.objects.count > 0 &&
                        viewModel.albumModel?.permission == .admin
                    )

                    Button(action: {
                        viewModel.toggleMovingMode(moveAll: true)
                    }) {
                        Label("Move all items", systemImage: "tray.and.arrow.up")
                    }.enabled(
                        viewModel.objects.count > 0 &&
                        viewModel.albumModel?.permission == .admin
                    )
                    
                    Button(action: {
                        viewModel.sync(userTriggered: true)
                    }) {
                        Label("Sync", systemImage: "goforward")
                    }
                    
                    Button(action: {
                        viewModel.markAllRead()
                    }) {
                        Label("Mark all read", systemImage: "scissors")
                    }.enabled(viewModel.objects.count > 0)
                } label: {
                    SFSymbolIcon(symbol: .ellipsis)
                }
                .enabled(signInManager.userIsSignedIn == true)
            }
        }
    }
}
