
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct GenericImageIcon: View {
    let model:GenericImageIconModel
    let object: ServerObjectModel
    let fileLabel: String
    
    // The default image must be square.
    static let defaultImageName = "ImageLoading" // From Asset catalog

    @State var fileImage: UIImage? = nil
    
    enum ImageStatus {
        case none
        case loading
        case loaded
    }
    
    @Binding var imageStatus: ImageStatus
    
    static let dimension: CGFloat = 75

    init(fileLabel: String, object: ServerObjectModel, imageStatus: Binding<ImageStatus>) {
        self.object = object
        self.fileLabel = fileLabel
        self.model = GenericImageIconModel(fileLabel: fileLabel)
        self._imageStatus = imageStatus
    }
    
    var body: some View {
        model.loadImage(fileGroupUUID: object.fileGroupUUID) { image in
            if let image = image {
                fileImage = image
                DispatchQueue.main.async {
                    if imageStatus != .loaded {
                        imageStatus = .loaded
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    if imageStatus != .none {
                        imageStatus = .none
                    }
                }
            }
        }

        return VStack {
            if let fileImage = fileImage, imageStatus == .loaded {
                ImageSizer(
                    image: Image(uiImage: fileImage)
                )
            }
            else if imageStatus == .loading {
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
