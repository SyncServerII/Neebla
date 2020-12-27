
import SwiftUI
import iOSSignIn

struct SharingView: View {
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
                    .frame(width: 100, height: 100)
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
    
    var body: some View {
        VStack {
            if viewModel.userSignedIn {
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


