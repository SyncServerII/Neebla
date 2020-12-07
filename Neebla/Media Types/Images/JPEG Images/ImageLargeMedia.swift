
import Foundation
import SwiftUI

struct ImageLargeMedia: View {
    let object: ServerObjectModel
    static let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel
    @ObservedObject var model:GenericImageModel
    
    init(object: ServerObjectModel) {
        self.object = object
        model = GenericImageModel(fileLabel: Self.imageFileLabel, fileGroupUUID: object.fileGroupUUID)
    }
    
    var body: some View {
        VStack {
            if let image = model.image {
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
