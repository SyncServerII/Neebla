
import Foundation
import SwiftUI

struct URLLargeMedia: View {
    let object: ServerObjectModel
    static let imageFileLabel = URLObjectType.previewImageDeclaration.fileLabel
    @ObservedObject var model:GenericImageModel
    @ObservedObject var urlModel:URLModel
    let tapOnLargeMedia: ()->()

    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
        self.object = object
        self.tapOnLargeMedia = tapOnLargeMedia
        model = GenericImageModel(fileLabel: Self.imageFileLabel, fileGroupUUID: object.fileGroupUUID)
        urlModel = URLModel(urlObject: object)
        urlModel.getContents()
    }
    
    var body: some View {
        VStack {
            ZoomableScrollView {
                VStack {
                    if let image = model.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    else if model.imageStatus == .gone {
                        GoneImage()
                    }
                    else {
                        EmptyView()
                    }
                }
                .onTapGesture {
                    tapOnLargeMedia()
                }
                
                if let contents = urlModel.contents, let url = contents.url {
                    Link(url.absoluteString, destination: url)
                        .font(.title)
                        .foregroundColor(.blue)
                }
                else if urlModel.gone {
                    Text("(Problem getting URL)")
                }
                
                Spacer()
            }
        }
    }
}
