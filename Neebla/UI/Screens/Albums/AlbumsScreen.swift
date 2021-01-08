
import Foundation
import SwiftUI
import SwiftUIRefresh
import SFSafeSymbols
import iOSShared

struct AlbumsScreen: View {
    @ObservedObject var viewModel:AlbumsViewModel
    @ObservedObject var userAlertModel:UserAlertModel
    
    init() {
        let userAlertModel = UserAlertModel()
        self.viewModel = AlbumsViewModel(userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }

    var body: some View {
        MenuNavBar(title: "Albums",
            rightNavbarButton:
                AnyView(
                    RightNavBarIcons(viewModel: viewModel)
                )
            ) {
            
            iPadConditionalScreenBodySizer {
                AlbumsScreenBody(viewModel: viewModel, userAlertModel: userAlertModel)
            }
        }
    }
}

struct AlbumsScreenBody: View {
    @ObservedObject var viewModel:AlbumsViewModel
    @ObservedObject var userAlertModel:UserAlertModel
    
    var body: some View {
        VStack {
            if viewModel.albums.count > 0 {
                AlbumsScreenAlbumList(viewModel: viewModel)
            }
            else {
                AlbumsScreenEmptyState(viewModel: viewModel)
            }
        }
        .pullToRefresh(isShowing: $viewModel.isShowingRefresh) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                viewModel.sync()
            }
        }
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
        // Fail to get the sheets displaying properly when there is more than one .sheet modifier. Working around this. See also https://stackoverflow.com/questions/58837007
        .sheet(item: $viewModel.activeSheet) { item in
            switch item {
            case .textInput:
                // Using this both for creating an album and for changing an existing album's name.
                TextInputModal(viewModel: viewModel)
                    .padding(20)
            case .albumSharing:
                if let album = viewModel.albumToShare {
                    AlbumSharingModal(album: album) { parameters in
                        viewModel.sharingMode = false
                        let contents = viewModel.emailContents(from: parameters)
                        viewModel.emailMessage = contents
                        viewModel.activeSheet = .email
                    }.padding(20)
                }
            case .email:
                if let emailMessage = viewModel.emailMessage {
                    MailView(emailContents: emailMessage, result: $viewModel.sendMailResult)
                }
            }
        }
        .onDisappear() {
            viewModel.sharingMode = false
        }
    }
}

struct AlbumsScreenEmptyState: View {
    @ObservedObject var viewModel:AlbumsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("No albums found.")
            Image("client-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 120)
            
            VStack {
                Text("Do you just need to refresh?")
                Button(
                    action: {
                        viewModel.sync()
                    },
                    label: {
                        SFSymbolIcon(symbol: .goforward)
                    }
                )
            }
            
            VStack {
                Text("Or perhaps you have none?")
                Button(action: {
                    viewModel.startCreateNewAlbum()
                }, label: {
                    SFSymbolIcon(symbol: .plusCircle)
                })
            }
        }
    }
}

struct AlbumsScreenAlbumList: View {
    @ObservedObject var viewModel:AlbumsViewModel

    var body: some View {
        /* Action states per row:
        1) Non-sharing mode.
            A tap on the main part of the row navigates to the album contents. Button blinks.
            If the user has .admin permissions, the pencil icon shows to the right. And a tap on the pencil brings up dialog to change the album name.
        2) Sharing mode.
            If the user has .admin permissions:
                Shows rectangle to the right.
                Tapping on the row anywhere, blinks button and brings up sharing modal.
            Otherwise:
                No rectangle shown.
                Taps have no effect.
         */
         
        List {
            // The `ForEach` appears needed to use the `listRowBackground`-- See https://stackoverflow.com/questions/56517904
            ForEach(viewModel.albums, id: \.sharingGroupUUID) { album in
                VStack {
                    if viewModel.sharingMode {
                        if album.permission.hasMinimumPermission(.admin) {
                            Button(action: {
                                viewModel.albumToShare = album
                                viewModel.activeSheet = .albumSharing
                                
                                // So when we come back from album sharing, the screen isn't in sharing mode.
                                viewModel.sharingMode = false
                            }, label: {
                                AlbumsScreenRow(album: album, viewModel: viewModel)
                            })
                        }
                        else {
                            AlbumsScreenRow(album: album, viewModel: viewModel)
                        }
                    }
                    else {
                        Button(action: {
                        }, label: {
                            AlbumsScreenRow(album: album, viewModel: viewModel)
                        })
                    }

                    // The `NavigationLink` works here because the `MenuNavBar` contains a `NavigationView`.
                    // Some hurdles here to get rid of the disclosure button at end of row: https://stackoverflow.com/questions/56516333
                    NavigationLink(destination:
                        AlbumItemsScreen(album: album.sharingGroupUUID, albumName: album.albumName ?? AlbumModel.untitledAlbumName)) {
                        EmptyView()
                    }
                    .frame(width: 0)
                    .opacity(0)
                    .enabled(!viewModel.sharingMode)
                }
            }
        }
    }
}

private struct RightNavBarIcons: View {
    @ObservedObject var viewModel:AlbumsViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Button(
                action: {
                    viewModel.sharingMode.toggle()
                },
                label: {
                    Icon(imageName: "Share", size: CGSize(width: 25, height: 25), blueAccent: false)
                        .accentColor(viewModel.sharingMode ? .gray : .blue)
                }
            )
            .frame(width: Icon.dimension, height: Icon.dimension)
            .enabled(viewModel.canSendMail && viewModel.albums.count > 0)
                                    
            Button(
                action: {
                    viewModel.startCreateNewAlbum()
                },
                label: {
                    SFSymbolIcon(symbol: .plusCircle)
                }
            )
        }
    }
}

private struct AlbumsScreenRow: View {
    @ObservedObject var album:AlbumModel
    @ObservedObject var viewModel:AlbumsViewModel
    var badgeText:String?
    
    init(album:AlbumModel, viewModel:AlbumsViewModel) {
        self.album = album
        self.viewModel = viewModel
        if let unreadCount = try? viewModel.unreadCountFor(album: album.sharingGroupUUID), unreadCount > 0 {
            badgeText = "\(unreadCount)"
        }
    }
    
    var body: some View {
        HStack {
            if let albumName = album.albumName {
                Text(albumName)
            }
            else {
                Text(AlbumModel.untitledAlbumName)
            }

            Spacer()
            
            if let badgeText = badgeText {
                Badge(badgeText)
            }
            
            // To change an album name and to share an album, you must have .admin permissions.
            if album.permission.hasMinimumPermission(.admin) {
                if viewModel.sharingMode {
                    Icon(imageName: "Share", size: CGSize(width: 25, height: 25))
                }
                else {
                    Button(action: {
                        viewModel.startChangeExistingAlbumName(sharingGroupUUID: album.sharingGroupUUID, currentAlbumName: album.albumName)
                    }, label: {
                        Image(systemName: SFSymbol.pencil.rawValue)
                    }).buttonStyle(PlainButtonStyle())
                }
            }

            // I'm using the .buttonStyle above b/c otherwise, I'm not getting the button tap. See https://www.hackingwithswift.com/forums/swiftui/is-it-possible-to-have-a-button-action-in-a-list-foreach-view/1153
            // See also https://stackoverflow.com/questions/56845670
        }
    }
}

private struct TextInputModal: View {
    @Environment(\.presentationMode) var isPresented
    @ObservedObject var viewModel:AlbumsViewModel
    
    init(viewModel:AlbumsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Text(viewModel.textInputTitle ?? "Album")
                
                HStack {
                    Button(action: {
                        self.isPresented.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.textInputAction?()
                        self.isPresented.wrappedValue.dismiss()
                    }) {
                        Text(viewModel.textInputActionButtonName ?? "Do It")
                    }.enabled(viewModel.textInputActionEnabled?() ?? true)
                }
            }
            
            TextField(viewModel.textInputInitialAlbumName ?? "",
                text: $viewModel.textInputAlbumName ?? "")
                .padding(10)
                .border(Color.gray.opacity(0.4))

            Spacer()
        }
    }
}


