
import Foundation
import SwiftUI

struct URLLargeMedia: View {
    let object: ServerObjectModel
    static let imageFileLabel = URLObjectType.previewImageDeclaration.fileLabel
    @ObservedObject var model:GenericImageModel
    @ObservedObject var urlModel:URLModel

    init(object: ServerObjectModel) {
        self.object = object
        model = GenericImageModel(fileLabel: Self.imageFileLabel, fileGroupUUID: object.fileGroupUUID)
        urlModel = URLModel(urlObject: object)
        urlModel.getContents()
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
            
            if let contents = urlModel.contents, let url = contents.url {
                Link(url.absoluteString, destination: url)
                    .font(.title)
                    .foregroundColor(.blue)
            }
        }
    }
}
