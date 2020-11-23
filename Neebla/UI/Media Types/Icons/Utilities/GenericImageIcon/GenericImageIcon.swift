
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
    @Binding var showingImage: Bool
    
    let dimension: CGFloat = 75
    
    init(fileLabel: String, object: ServerObjectModel, showingImage: Binding<Bool>) {
        self.object = object
        self.fileLabel = fileLabel
        self.model = GenericImageIconModel(fileLabel: fileLabel)
        self._showingImage = showingImage
    }
    
    var body: some View {
        model.loadImage(fileGroupUUID: object.fileGroupUUID) { image in
            fileImage = image
        }

        return VStack {
            image(uiImage:fileImage)
                .resizable()
                .squareImage()
                .cornerRadius(4.0)
            }.frame(width:dimension, height:dimension)
    }
    
    func image(uiImage:UIImage?, default imageName: String = "ImageLoading") -> Image {
        if let uiImage = uiImage {
            // Get rid of warning
            DispatchQueue.main.async {
                if showingImage != true {
                    showingImage = true
                }
            }
            return Image(uiImage: uiImage)
        }
        else {
            // Get rid of warning
            DispatchQueue.main.async {
                if showingImage != false {
                    showingImage = false
                }
            }
            return Image(Self.defaultImageName)
        }
    }
}

