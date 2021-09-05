import Foundation
import SwiftUI
import Combine

struct AlbumItemsScreenCell: View {
    @StateObject var object:ServerObjectModel
    @StateObject var viewModel:AlbumItemsViewModel
    let config: IconConfig
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        AnyIcon(model: AnyIconModel(object: object), config: config,
            emptyUpperRightView: viewModel.changeMode == .none,
            upperRightView: {
                UpperRightChangeIcon(object: object, viewModel: viewModel)
            })
    }
}

private struct UpperRightChangeIcon: View {
    @StateObject var object:ServerObjectModel
    @StateObject var viewModel:AlbumItemsViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch viewModel.changeMode {
        case .none:
            EmptyView()
        case .sharing, .moving, .moveAll:
            Icon(
                imageName:
                    viewModel.changeMode == .sharing ?
                        "Share" :
                        "Move",
                size: CGSize(width: 25, height: 25), blueAccent: false)
                .padding(5)
                .background(colorScheme == .light ?
                    Color.white.opacity(0.7) : Color(UIColor.darkGray).opacity(0.8))
                .if (colorScheme == .dark && !viewModel.itemsToChange.contains(object)) {
                    $0.foregroundColor(Color.black)
                }
                .if (viewModel.itemsToChange.contains(object)) {
                    $0.foregroundColor(.blue)
                }
        }
    }
}
