
import SwiftUI
import iOSSignIn
import iOSShared

struct SharingView: View {
    @ObservedObject var viewModel:ShareViewModel
    let insideViewOffset: CGFloat = 30
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    
    init(viewModel: ShareViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            VStack {
                ButtonBar(viewModel: viewModel)
                Spacer()
                Spacer()
                Container(viewModel: viewModel)
                Spacer()
                ItemPreview(viewModel: viewModel, iconConfig: .large)
                Spacer()
            }
            .frame(
                width: viewModel.width - insideViewOffset,
                height: viewModel.height - insideViewOffset)
        }
        .frame(width: viewModel.width, height: viewModel.height)
        .background(Color(UIColor.systemBackground))
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
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


