
import SwiftUI
import iOSSignIn

struct SharingView: View {
    @ObservedObject var viewModel:ViewModel
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
    }
}

struct Container: View {
    @ObservedObject var viewModel:ViewModel
    
    var body: some View {
        VStack {
            if viewModel.userSignedIn {
                UploadToAlbumView(viewModel: viewModel)
            }
            else {
                Text("You are not signed in. Please sign in using the Neebla app.")
                    .foregroundColor(Color(UIColor.label))
            }
        }
    }
}

struct SharingView_Previews: PreviewProvider {
    static let viewModel = ViewModel()
    static var previews: some View {
        viewModel.width = 250
        viewModel.height = 450
        viewModel.sharingGroups = [
            SharingGroupData(id: UUID(), name: "Group 1"),
            SharingGroupData(id: UUID(), name: "Group 2"),
            SharingGroupData(id: UUID(), name: "Group 3"),
            SharingGroupData(id: UUID(), name: "Group 4"),
            SharingGroupData(id: UUID(), name: "Group 5"),
            SharingGroupData(id: UUID(), name: "Group 6")
        ]
        return SharingView(viewModel: viewModel)
    }
}
