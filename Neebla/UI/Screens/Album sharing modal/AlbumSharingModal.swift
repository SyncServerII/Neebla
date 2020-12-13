
import Foundation
import SwiftUI
import ServerShared
import RadioGroup
import WebKit

struct AlbumSharingModal: View {
    @ObservedObject var userAlertModel: UserAlertModel
    @ObservedObject var viewModel: AlbumSharingModalModel
    let albumName: String
    
    init(album: AlbumModel) {
        let userAlertModel = UserAlertModel()
        self.userAlertModel = userAlertModel
        self.viewModel = AlbumSharingModalModel(album: album, userAlertModel: userAlertModel)
        albumName = album.albumName ?? AlbumsViewModel.untitledAlbumName
    }
    
    var body: some View {
        VStack(spacing: 30) {
            ScreenButtons(viewModel: viewModel)
            Text("Invite others to '\(albumName)' album")
                .font(.title)
                
            ScrollView {
                VStack(spacing: 20) {
                    NumberOfPeople(viewModel: viewModel)
                    Divider()
                    PermissionPicker(viewModel: viewModel)
                    Divider()
                    AllowSocialAcceptance(viewModel: viewModel)
                    Divider()
                    if let helpText = viewModel.helpString {
                        HelpInfo(helpStringHTML: helpText)
                    }
                }
            }
        }
        .padding([.leading, .trailing, .bottom], 10)
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
    }
}

private struct NumberOfPeople: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        HStack {
            Text("Number of people to invite:")
            Spacer()
        }
        
        HStack {
            Slider(value: $viewModel.numberOfPeopleToInviteRaw, in: 1...Float(ServerConstants.maxNumberSharingInvitationAcceptors))
            Text("\($viewModel.numberOfPeopleToInvite.wrappedValue)")
                .padding(.leading, 20)
        }
    }
}

private struct HelpInfo: View {
    let helpStringHTML: String
    
    var body: some View {
        HStack {
            Text("What are you sharing?")
            Spacer()
        }
        
        HTMLStringView(htmlContent: helpStringHTML)
            // This is needed or the text doesn't get shown.
            // See https://developer.apple.com/forums/thread/653935 and
            // https://stackoverflow.com/questions/56892691
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, idealHeight: 500, maxHeight: .infinity, alignment: .center)
    }
}

private struct HTMLStringView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

private struct AllowSocialAcceptance: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        Toggle(isOn: $viewModel.allowSocialAcceptance, label: {
            Text("Allow social acceptance?")
        })
        .padding(.trailing, 5) // get clipping to right without this.
    }
}

private struct PermissionPicker: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        HStack {
            Text("Permissions for people invited")
            Spacer()
        }
        
        HStack {
            RadioGroupPicker(
                selectedIndex: $viewModel.permissionSelection,
                titles: [
                    "Read-only",
                    "Read & Change",
                    "Read, Change, and Invite"
                ]
            ).spacing(5)
            .fixedSize()
            .padding(.leading, 20)
            
            Spacer()
        }
    }
}

private struct ScreenButtons: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        HStack {
            Button(action: {
            
            }, label: {
                Text("Cancel")
            })
            
            Spacer()
            
            Button(action: {
            
            }, label: {
                Text("Invite")
            })
        }
    }
}
