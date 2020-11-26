
import Foundation
import SwiftUI

struct URLLargeMedia: View {
    let object: ServerObjectModel
    static let imageFileLabel = URLObjectType.previewImageDeclaration.fileLabel
    let model = GenericImageModel(fileLabel: Self.imageFileLabel)
    @State var image: UIImage?
    @ObservedObject var urlModel:URLModel

    init(object: ServerObjectModel) {
        self.object = object
        urlModel = URLModel(urlObject: object)
        urlModel.getContents()
    }
    
    var body: some View {
        model.loadImage(fileGroupUUID: object.fileGroupUUID) { image in
            DispatchQueue.main.async {
                self.image = image
            }
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
            
            if let contents = urlModel.contents, let url = contents.url {
                Link(url.absoluteString, destination: url)
                    .font(.title)
                    .foregroundColor(.blue)
            }
        }
    }
}
