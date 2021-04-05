
import Foundation
import SwiftUI

struct URLIcon: View {
    let urlFileLabel = URLObjectType.previewImageDeclaration.fileLabel
    let object: ServerObjectModel
    @ObservedObject var model:URLModel
    @ObservedObject var imageModel:GenericImageModel
    let config: IconConfig
    
    init(object: ServerObjectModel, config: IconConfig) {
        self.object = object
        model = URLModel(urlObject: object)
        imageModel = GenericImageModel(fileLabel: urlFileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: config.iconSize)
        self.config = config
        model.getDescriptionText()
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(.model(imageModel), config: config)
                .lowerRightText("url")

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

