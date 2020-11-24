
import Foundation
import SwiftUI

struct ImageLargeMedia: View {
    let object: ServerObjectModel
    static let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel
    let model = GenericImageModel(fileLabel: Self.imageFileLabel)
    @State var image: UIImage?
    
    var body: some View {
        model.loadImage(fileGroupUUID: object.fileGroupUUID) { image in
            self.image = image
        }
        
        return VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            else {
                EmptyView()
            }
        }
    }
}
