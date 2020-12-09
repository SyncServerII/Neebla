
import Foundation
import SwiftUI

struct URLIcon: View {
    let urlFileLabel = URLObjectType.previewImageDeclaration.fileLabel
    let object: ServerObjectModel
    @ObservedObject var model:URLModel
    @ObservedObject var imageModel:GenericImageModel
    
    init(object: ServerObjectModel) {
        self.object = object
        model = URLModel(urlObject: object)
        imageModel = GenericImageModel(fileLabel: urlFileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: CGSize(width: GenericImageIcon.dimension, height: GenericImageIcon.dimension))
        model.getDescriptionText()
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(fileLabel: urlFileLabel, object: object, model: imageModel)
            
            if imageModel.imageStatus == .none || imageModel.imageStatus == .loaded {
                TextInLowerRight(text: "url")
            }
            
            if imageModel.imageStatus == .none {
                // If there is no image, put some text from the .url file into the icon.
                DescriptionText(description: model.description ?? "")
            }
        }
    }
}

struct DescriptionText: View {
    let description: String
    
    var body: some View {
        VStack {
            Text(description)
            Spacer()
        }
    }
}

