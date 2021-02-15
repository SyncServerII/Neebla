import Foundation
import SwiftUI
import Combine

struct AlbumItemsScreenCell: View {
    @ObservedObject var object:ServerObjectModel
    @ObservedObject var viewModel:AlbumItemsViewModel
    @Environment(\.colorScheme) var colorScheme
    let config: IconConfig

    var body: some View {
        AnyIcon(object: object, config: config,
            upperRightView: viewModel.sharing ? sharingView() : nil)
    }
    
    private func sharingView() -> AnyView {
        AnyView(
            Icon(imageName: "Share",
                size: CGSize(width: 25, height: 25), blueAccent: false)
                .padding(5)
                .background(colorScheme == .light ?
                    Color.white.opacity(0.7) : Color(UIColor.darkGray).opacity(0.8))
                .if (colorScheme == .dark && !viewModel.itemsToShare.contains(object.fileGroupUUID)) {
                    $0.foregroundColor(Color.black)
                }
                .if(viewModel.itemsToShare.contains(object.fileGroupUUID)) {
                    $0.foregroundColor(.blue)
                }
        )
    }
}
