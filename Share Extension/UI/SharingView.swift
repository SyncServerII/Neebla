
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
            if manager.userIsSignedIn {
                UploadToAlbumView(viewModel: viewModel)
            }
            else {
                Text("You are not signed in. Please sign in using the Neebla app.")
                    .foregroundColor(Color(UIColor.label))
                    .font(.title)
            }
        }
    }
}


