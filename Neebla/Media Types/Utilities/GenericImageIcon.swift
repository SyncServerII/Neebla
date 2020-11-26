
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared
import Toucan

struct GenericImageIcon: View {
    // Image icons are square.
    static let dimension: CGFloat = 75
    
    @ObservedObject var model:GenericImageModel
    let object: ServerObjectModel
    let fileLabel: String
    
    // The default image must be square.
    static let defaultImageName = "ImageLoading" // From Asset catalog
        
    init(fileLabel: String, object: ServerObjectModel, model:GenericImageModel? = nil) {
        self.object = object
        self.fileLabel = fileLabel
        
        if let model = model {
            self.model = model
        }
        else {
            self.model = GenericImageModel(fileLabel: fileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: CGSize(width: Self.dimension, height: Self.dimension))
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
