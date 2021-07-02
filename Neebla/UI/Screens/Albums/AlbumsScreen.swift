
import Foundation
import SwiftUI
import SwiftUIRefresh
import SFSafeSymbols
import iOSShared
import iOSSignIn

struct AlbumsScreen: View {
    static let background = Color.gray.opacity(0.2)
    
    @StateObject var viewModel = AlbumsViewModel()
    
    var body: some View {
        MenuNavBar(title: "Albums",
            rightNavbarButton:
                AnyView(
                    RightNavBarIcons(viewModel: viewModel)
                )
            ) {
            
            iPadConditionalScreenBodySizer {
                AlbumsScreenBody(viewModel: viewModel)
            }
        }
    }
}

struct AlbumsScreenBody: View {
    @StateObject var viewModel:AlbumsViewModel
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    
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
            viewModel.sync(userTriggered: true)
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        // Fail to get the sheets displaying properly when there is more than one .sheet modifier. Working around this. See also https://stackoverflow.com/questions/58837007
        .sheetyDisplayer(item: $viewModel.activeSheet, subscriber: alerty) { item in
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
            if viewModel.sharingMode {
                viewModel.sharingMode = false
            }
        }
        .onAppear() {
            if viewModel.firstAppearance {
                // Don't do this in the model `init`: Because of the way the code is structured the model init can occur before a user is signed in.
                viewModel.sync()
                
                // Doing this in the Albums screen because it's the main entry point to albums and eventually adding items to albums-- which can cause push notifications to be sent.
                viewModel.checkForNotificationAuthorization()
                
                viewModel.firstAppearance = false
            }
        }
    }
}

struct AlbumsScreenEmptyState: View {
    @ObservedObject var viewModel:AlbumsViewModel
    @StateObject var signInManager = Services.session.signInServices.manager

    var body: some View {
        VStack(spacing: 20) {
            Text("No albums found.")
            Image("client-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 120)
            
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
                    Text("Or perhaps you have none?")
                    Button(action: {
                        viewModel.startCreateNewAlbum()
                    }, label: {
                        SFSymbolIcon(symbol: .plusCircle)
                    })
                }
            
            default:
                VStack {
                    Text("Please sign in to refresh or add an album.")
                }
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
                                AlbumsScreenRow(sharingGroupUUID: album.sharingGroupUUID, viewModel: viewModel)
                            })
                        }
                        else {
                            AlbumsScreenRow(sharingGroupUUID: album.sharingGroupUUID, viewModel: viewModel)
                        }
                    }
                    else {
                        Button(action: {
                        }, label: {
                            AlbumsScreenRow(sharingGroupUUID: album.sharingGroupUUID, viewModel: viewModel)
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
                .listRowBackground(AlbumsScreen.background)
            }
        }
        .cornerRadius(5, antialiased: true)
        .if(!UIDevice.isPad) {
            $0.padding(10)
        }
    }
}

private struct RightNavBarIcons: View {
    @ObservedObject var viewModel:AlbumsViewModel
    @ObservedObject var signInManager: SignInManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.menuState) var menuState
    
    init(viewModel:AlbumsViewModel) {
        self.viewModel = viewModel
        signInManager = Services.session.signInServices.manager
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(
                action: {
                    viewModel.sharingMode.toggle()
                },
                label: {
                    Icon(imageName: Images.shareIcon(lightMode:colorScheme == .light),
                        size: CGSize(width: 25, height: 25), blueAccent: false)
                        .accentColor(viewModel.sharingMode ? .gray : .blue)
                }
            )
            .frame(width: Icon.dimension, height: Icon.dimension)
            .enabled(viewModel.canSendMail && viewModel.albums.count > 0 && signInManager.userIsSignedIn == true)
                                    
            Button(
                action: {
                    viewModel.startCreateNewAlbum()
                },
                label: {
                    SFSymbolIcon(symbol: .plusCircle)
                }
            )
            .enabled(signInManager.userIsSignedIn == true
                && !viewModel.sharingMode)
        }
        .onReceive(menuState.$displayed, perform: { _ in
            if menuState.displayed && viewModel.sharingMode {
                viewModel.sharingMode = false
            }
        })
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


