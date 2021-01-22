
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct GenericImageIcon: View {
    @ObservedObject var model:GenericImageModel
    static let loadingImageIcon = "ImageLoading" // From Asset catalog
    let config: IconConfig
    
    enum ModelSetup {
        case object(fileLabel:String, object: ServerObjectModel)
        case url(URL)
        case model(GenericImageModel)
    }
    
    init(_ modelSetup: ModelSetup, config: IconConfig) {
        self.config = config
        switch modelSetup {
        case .model(let model):
            self.model = model
        case .object(fileLabel: let fileLabel, object: let object):
            model = GenericImageModel(fileLabel: fileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: config.iconSize)
        case .url(let url):
            model = GenericImageModel(fullSizeImageURL: url, imageScale: config.iconSize)
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
                    // This doesn't give what I want. It gives clipped coners.
                    //.border(Color.black, width: 1)
                    //.cornerRadius(ImageSizer.cornerRadius)
                    // The following is better. See https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-a-border-around-a-view
                    .overlay(
                        RoundedRectangle(cornerRadius: ImageSizer.cornerRadius)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
        }.frame(width:config.dimension, height:config.dimension)
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
