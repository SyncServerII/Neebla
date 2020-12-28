
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct GenericImageIcon: View {
    @ObservedObject var model:GenericImageModel
    static let dimension: CGFloat = 75
    static let defaultImageName = "ImageLoading" // From Asset catalog

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
            //model = GenericImageModel(fullSizeImageURL: url, imageScale: nil)
            model = GenericImageModel(fullSizeImageURL: url, imageScale: CGSize(width: Self.dimension, height: Self.dimension))
        }
    }
    
    var body: some View {
        VStack {
            if let fileImage = model.image, model.imageStatus == .loaded {
                ImageSizer(
                    image: Image(uiImage: fileImage)
                )
            }
            else if model.imageStatus == .loading {
                ImageSizer(
                    image: Image(Self.defaultImageName)
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
