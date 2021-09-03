
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct GenericImageIcon: View {
    @ObservedObject var model:GenericImageModel
    let config: IconConfig
    @Environment(\.colorScheme) var colorScheme
    static let loadingImageIcon = "ImageLoading" // From Asset catalog
    static let loadingImageIconDarkMode = "ImageLoadingDarkMode" // From Asset catalog

    enum ModelSetup {
        case object(fileLabel:String, object: ServerObjectModel)
        case url(URL)
        case model(GenericImageModel)
    }
    
    static func setupModel(_ modelSetup: ModelSetup, iconSize: CGSize) -> GenericImageModel {
        switch modelSetup {
        case .model(let model):
            return model
        case .object(fileLabel: let fileLabel, object: let object):
            return GenericImageModel(fileLabel: fileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: iconSize)
        case .url(let url):
            return GenericImageModel(fullSizeImageURL: url, imageScale: iconSize)
        }
    }
    
    // Goal for icon display:
    // a) If no image and not downloading or preparing to show downloaded image, show white blank icon.
    // b) If image is Gone, then show Gone image.
    // c) If downloading or preparing to show dowloaded image, show a "busy" or "downloading" temporary icon.
    // d) If have the image, show it.

    var body: some View {
        VStack {
            if let fileImage = model.image, model.imageStatus == .loaded {
                ImageSizer(
                    image: Image(uiImage: fileImage)
                )
            }
            else if model.imageStatus == .rendering || model.imageStatus == .downloading {
                ImageSizer(
                    image:
                        colorScheme == .light ?
                            Image(Self.loadingImageIcon) :
                            Image(Self.loadingImageIconDarkMode)
                )
            }
            else if model.imageStatus == .gone {
                GoneImage()
            }
            else { // imageStatus == .none
                Rectangle()
                    .fill(colorScheme == .light ? Color.white : Color(UIColor.darkGray))
                    // This doesn't give what I want. It gives clipped corners.
                    //.border(Color.black, width: 1)
                    //.cornerRadius(ImageSizer.cornerRadius)
                    // The following is better. See https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-a-border-around-a-view
                    .overlay(
                        RoundedRectangle(cornerRadius: ImageSizer.cornerRadius)
                            .stroke(colorScheme == .light ? Color.black : Color.gray, lineWidth: 1)
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
