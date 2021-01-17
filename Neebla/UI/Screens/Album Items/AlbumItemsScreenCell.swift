import Foundation
import SwiftUI
import Combine

struct AlbumItemsScreenCell: View {
    @ObservedObject var object:ServerObjectModel
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    var body: some View {
        AnyIcon(object: object,
            upperRightView: viewModel.sharing ? sharingView() : nil)
    }
    
    private func sharingView() -> AnyView {
        AnyView(
            Icon(imageName: "Share", size: CGSize(width: 25, height: 25), blueAccent: false)
                .if(viewModel.itemsToShare.contains(object.fileGroupUUID)) {
                    $0.foregroundColor(.blue)
                }
        )
    }
}
