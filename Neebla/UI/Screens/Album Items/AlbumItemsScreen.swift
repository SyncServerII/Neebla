
import Foundation
import SwiftUI
import SFSafeSymbols
import CustomModalView
import iOSShared

struct AlbumItemsScreen: View {
    let sharingGroupUUID: UUID
    
    init(album sharingGroupUUID: UUID) {
        self.sharingGroupUUID = sharingGroupUUID
    }
    
    var body: some View {
        iPadConditionalScreenBodySizer {
            AlbumItemsScreenBody(album: sharingGroupUUID)
                .background(Color.screenBackground)
        }
    }
}

struct AlbumItemsScreenBody: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    @ObservedObject var userAlertModel:UserAlertModel
    
    /* It seems hard to get the spacing to work out reasonably. At first, it looked OK on iPhone 11 but not on iPhone 8-- on iPhone 8 there was no spacing. In this case I was using:
    
        let gridItemLayout = [GridItem(.adaptive(minimum: 50), spacing: 20)]
      
      Just changing the `spacing` doesn't really help. What seems to be going on is that the LazyVGrid is trying to fit as many cells as it can per row. And if that means no spacing, then there is no spacing.
      
      What's helping is to use the image dimension as the minimum. This is looking OK on iPhone 8 and iPhone 11.
    */
    let gridItemLayout = [
        GridItem(.adaptive(minimum: GenericImageIcon.dimension), spacing: 5)
    ]
    
    @State var object: ServerObjectModel?
    
    init(album sharingGroupUUID: UUID) {
        let userAlertModel = UserAlertModel()
        self.viewModel = AlbumItemsViewModel(album: sharingGroupUUID, userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }
    
    var body: some View {
        VStack {
            RefreshableScrollView(refreshing: $viewModel.loading) {
                LazyVGrid(columns: gridItemLayout) {
                    ForEach(viewModel.objects, id: \.fileGroupUUID) { item in
                        AlbumItemsScreenCell(object: item, viewModel: viewModel)
                            .onTapGesture {
                                if viewModel.sharing {
                                    viewModel.toggleItemToShare(fileGroupUUID: item.fileGroupUUID)
                                }
                                else {
                                    object = item
                                    viewModel.showCellDetails = true
                                }
                            }
                    } // end ForEach
                } // end LazyVGrid
            }.padding(5)
            
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
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
        .navigationBarTitle("Album Contents")
        .navigationBarItems(trailing:
            AlbumItemsScreenNavButtons(viewModel: viewModel)
        )
        .disabled(viewModel.addNewItem)
        // For some reason, it's important that this .sheet come before the .modal for `AddItemModal`. Otherwise, I can't use the buttons in the `AddItemModal`. Perhaps because the modal contains a .sheet?
        .sheet(isPresented: $viewModel.completeSharing) {
            ActivityViewController(activityItems: viewModel.shareActivityItems())
                .onAppear() {
                    // Switch out of sharing mode, so when user comes back they don't have the selection state-- which doesn't seem right.
                    viewModel.sharing = false
                }
        }
        .modal(isPresented: $viewModel.addNewItem) {
            AddItemModal(viewModel: viewModel)
                .padding(20)
        }
        .modalStyle(DefaultModalStyle())
        .onDisappear {
            // I'm having a problem with the modal possibly being presented, the user navigating away, coming back and the modal still being present.
            // See also https://github.com/jankaltoun/CustomModalView/issues/1
            if viewModel.addNewItem == true {
                viewModel.addNewItem = false
            }
        }
    }
}

private struct AlbumItemsScreenNavButtons: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    var body: some View {
        if viewModel.sharing && viewModel.itemsToShare.count > 0 {
            AlbumItemsScreenNavSharingButtons(viewModel: viewModel)
        }
        else {
            AlbumItemsScreenNavRegularButtons(viewModel: viewModel)
        }
    }
}

private struct AlbumItemsScreenNavRegularButtons: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Button(
                action: {
                    viewModel.startNewAddItem()
                },
                label: {
                    SFSymbolIcon(symbol: .plusCircle)
                }
            )
            
            Menu {
                Button(action: {
                    viewModel.sharing = true
                }) {
                    Label("Share items", image: "Share")
                }.enabled(viewModel.objects.count > 0)
                
                Button(action: {
                    viewModel.sync()
                }) {
                    Label("Sync", systemImage: "goforward")
                }
            } label: {
                SFSymbolIcon(symbol: .ellipsis)
            }
        }
    }
}

private struct AlbumItemsScreenNavSharingButtons: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    var body: some View {
        HStack {
            Button(
                action: {
                    viewModel.completeSharing = true
                },
                label: {
                    SFSymbolIcon(symbol: .squareAndArrowUp)
                }
            )
            
            Button(
                action: {
                    viewModel.sharing = false
                    viewModel.itemsToShare.removeAll()
                },
                label: {
                    SFSymbolIcon(symbol: .xmark)
                }
            )
        }
    }
}
