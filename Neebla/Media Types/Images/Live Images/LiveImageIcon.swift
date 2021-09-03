
import Foundation
import SwiftUI

struct LiveImageIcon: View {
    @ObservedObject var model: GenericImageModel
    let config: IconConfig
    
    init(object: ServerObjectModel, config: IconConfig) {
        model = GenericImageModel(fileLabel: LiveImageObjectType.imageDeclaration.fileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: config.iconSize)
        self.config = config
    }
    

    var body: some View {
        ZStack {
            GenericImageIcon(model: model, config: config)
                .lowerRightText("live")
        }
    }
}
