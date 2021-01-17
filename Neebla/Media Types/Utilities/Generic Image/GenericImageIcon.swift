
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct GenericImageIcon: View {
    @ObservedObject var model:GenericImageModel
    static let dimension: CGFloat = 75
    static let loadingImageIcon = "ImageLoading" // From Asset catalog

    enum Parameters {
        case object(fileLabel:String, object: ServerObjectModel)
        case url(URL)
        case model(GenericImageModel)
    }
    
    init(_ parameters: Parameters) {
        switch parameters {
        case .model(let model):
            self.model = model
        case .object(fileLabel: let fileLabel, object: let object):
            model = GenericImageModel(fileLabel: fileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: CGSize(width: Self.dimension, height: Self.dimension))
        case .url(let url):
            model = GenericImageModel(fullSizeImageURL: url, imageScale: CGSize(width: Self.dimension, height: Self.dimension))
        }
    }
    
    // Goal for icon display:
    // a) If no image and not downloading or preparing to show downloaded image, show white blank icon.
    // b) If downloading or preparing to show dowloaded image, show a "busy" or "downloading" temporary icon.
    // c) If have the image, show it.

    var body: some View {
        VStack {
            if let fileImage = model.image, model.imageStatus == .loaded {
                ImageSizer(
                    image: Image(uiImage: fileImage)
                )
            }
            else if model.imageStatus == .rendering || model.imageStatus == .downloading {
                ImageSizer(
                    image: Image(Self.loadingImageIcon)
                )
            }
            else { // imageStatus == .none
                Rectangle()
                    .fill(Color.white)
                    .border(Color.black, width: 1)
                    .cornerRadius(ImageSizer.cornerRadius)
            }
        }.frame(width:Self.dimension, height:Self.dimension)
    }
}

struct ImageSizer: View {
    static let cornerRadius: CGFloat = 4
    let image:Image
    
    var body: some View {
        image
            .resizable()
            .squareImage()
            .cornerRadius(Self.cornerRadius)
    }
}
