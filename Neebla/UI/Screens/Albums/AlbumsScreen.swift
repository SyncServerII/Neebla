
import Foundation
import SwiftUI
import SwiftUIRefresh
import SFSafeSymbols
import CustomModalView

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
                                    viewModel.presentAlbumSharingModal = true
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
                            AlbumItemsScreen(album: album.sharingGroupUUID)) {
                            EmptyView()
                        }
                        .frame(width: 0)
                        .opacity(0)
                        .enabled(!viewModel.sharingMode)
                    }
                }
            }
            .pullToRefresh(isShowing: $viewModel.isShowingRefresh) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    viewModel.sync()
                }
            }
            .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
            .disabled(viewModel.presentTextInput)
            // Using this both for creating an album and for changing an existing album's name.
            .modal(isPresented: $viewModel.presentTextInput) {
                TextInputModal(viewModel: viewModel)
                    .padding(20)
            }
            .sheet(isPresented: $viewModel.presentAlbumSharingModal) {
                if let album = viewModel.albumToShare {
                    AlbumSharingModal(album: album) { invitationCode in
                        viewModel.emailMessageBody = invitationCode.uuidString
                        viewModel.presentEmailInvitation = true
                    }.padding(20)
                }
            }
//            .sheet(isPresented: $viewModel.presentEmailInvitation) {
//                if let messageBody = viewModel.emailMessageBody {
//                    MailView(messageBody: messageBody, result: $viewModel.sendMailResult)
//                }
//            }
            .modalStyle(DefaultModalStyle(padding: 20))
            .onDisappear() {
                viewModel.sharingMode = false
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
                    NavBarIcon(imageName: "Share", size: CGSize(width: 25, height: 25), blueAccent: false)
                        .if(viewModel.sharingMode) {
                            $0.accentColor(.gray)
                        }
                        .if(!viewModel.sharingMode) {
                            $0.accentColor(.blue)
                        }
                }
            )
            .frame(width: NavBarIcon.dimension, height: NavBarIcon.dimension)
            .enabled(viewModel.canSendMail)
                                    
            Button(
                action: {
                    viewModel.startCreateNewAlbum()
                },
                label: {
                    SFSymbolNavBar(symbol: .plusCircle)
                }
            )
        }
    }
}

private struct AlbumsScreenRow: View {
    @ObservedObject var album:AlbumModel
    @ObservedObject var viewModel:AlbumsViewModel
    
    var body: some View {
        HStack {
            if let albumName = album.albumName {
                Text(albumName)
            }
            else {
                Text(AlbumsViewModel.untitledAlbumName)
            }

            Spacer()
            
            // To change an album name and to share an album, you must have .admin permissions.
            if album.permission.hasMinimumPermission(.admin) {
                if viewModel.sharingMode {
                    Image(systemName: SFSymbol.square.rawValue)
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
    @Environment(\.modalPresentationMode) var modalPresentationMode: Binding<ModalPresentationMode>
    @ObservedObject var viewModel:AlbumsViewModel
    
    init(viewModel:AlbumsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text(viewModel.textInputTitle ?? "Album:")
            TextField(viewModel.textInputInitialAlbumName ?? "",
                text: $viewModel.textInputAlbumName ?? "")
            
            HStack {
                Button(action: {
                    self.modalPresentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.textInputAction?()
                    self.modalPresentationMode.wrappedValue.dismiss()
                }) {
                    Text(viewModel.textInputActionButtonName ?? "Do It")
                }.enabled(
                    viewModel.textInputNewAlbum
                    || !viewModel.textInputNewAlbum &&
                        (viewModel.textInputAlbumName != viewModel.textInputPriorAlbumName) && viewModel.textInputAlbumName != nil)
            }
        }
    }
}


