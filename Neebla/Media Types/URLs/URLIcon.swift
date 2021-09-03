
import Foundation
import SwiftUI

struct URLIcon: View {
    @ObservedObject var model:URLModel
    @ObservedObject var imageModel:GenericImageModel
    let config: IconConfig
    
    init(object: ServerObjectModel, config: IconConfig) {
        model = URLModel(urlObject: object)
        imageModel = GenericImageModel(fileLabel: URLObjectType.previewImageDeclaration.fileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: config.iconSize)
        self.config = config
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(model:imageModel, config: config)
                .lowerRightText("url")

            if imageModel.imageStatus == .none {
                // If there is no image, put some text from the .url file into the icon.
                DescriptionText(description: model.description ?? "")
            }
        }.onAppear() {
            model.getDescriptionText()
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

