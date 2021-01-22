
import Foundation
import SwiftUI

struct ImageIcon: View {
    let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel
    let object: ServerObjectModel
    let config: IconConfig
    
    init(object: ServerObjectModel, config: IconConfig) {
        self.object = object
        self.config = config
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(.object(fileLabel: imageFileLabel, object: object), config: config)
        }
    }
}
