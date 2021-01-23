
import SwiftUI
import iOSSignIn

struct SharingView: View {
    static let itemPreviewSize = CGSize(width: 150, height: 150)
    @ObservedObject var viewModel:ShareViewModel
    @ObservedObject var userAlertModel:UserAlertModel
    
    init(viewModel: ShareViewModel) {
        self.viewModel = viewModel
        userAlertModel = viewModel.userAlertModel
    }

    let insideViewOffset: CGFloat = 30
    
    var body: some View {
        return VStack {
            VStack {
                ButtonBar(viewModel: viewModel)
                Spacer()
                Spacer()
                Container(viewModel: viewModel)
                Spacer()
                ItemPreview(viewModel: viewModel)
                    .frame(width: Self.itemPreviewSize.width, height: Self.itemPreviewSize.height)
                Spacer()
            }
            .frame(
                width: viewModel.width - insideViewOffset,
                height: viewModel.height - insideViewOffset)
        }
        .frame(width: viewModel.width, height: viewModel.height)
        .background(Color(UIColor.systemBackground))
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
    }
}

struct Container: View {
    @ObservedObject var viewModel:ShareViewModel
    @ObservedObject var manager: iOSSignIn.SignInManager

    init(viewModel:ShareViewModel) {
        self.viewModel = viewModel
        manager = Services.session.signInServices.manager
    }
    
    var body: some View {
        VStack {
            switch manager.userIsSignedIn {
            case .none:
                EmptyView()
            case .some(true):
                UploadToAlbumView(viewModel: viewModel)
            case .some(false):
                if manager.currentSignInClassName == nil {
                    textToShow("You are not signed in. Please sign in using the Neebla app.")
                        .font(.title)
                }
                else {
                    textToShow("You are signed into Neebla, but unfortunately that sign in doesn't work with the sharing extension. Please add the media within Neebla.")
                        .font(.title2)
                }
            }
        }
    }
    
    func textToShow(_ string: String) -> Text {
        return Text(string)
            .foregroundColor(Color(UIColor.label))
    }
}


