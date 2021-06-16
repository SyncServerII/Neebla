import Foundation
import SwiftUI
import Combine

struct AlbumItemsScreenCell: View {
    @ObservedObject var object:ServerObjectModel
    @ObservedObject var viewModel:AlbumItemsViewModel
    let config: IconConfig
    let cellModel:AlbumItemsScreenCellModel
    @Environment(\.colorScheme) var colorScheme
    
    init(object:ServerObjectModel, viewModel:AlbumItemsViewModel, config: IconConfig) {
        self.object = object
        self.viewModel = viewModel
        self.config = config
        cellModel = AlbumItemsScreenCellModel(object: object)
    }

    var body: some View {
        AnyIcon(object: object, config: config,
            upperRightView: viewModel.sharing ? sharingView() : cellModel.badgeView)
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
