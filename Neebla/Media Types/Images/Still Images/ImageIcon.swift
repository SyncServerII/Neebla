
import Foundation
import SwiftUI

struct ImageIcon: View {
    let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel
    @ObservedObject var object: ServerObjectModel
    let config: IconConfig
    
    var body: some View {
        ZStack {
            GenericImageIcon(model:
                GenericImageIcon.setupModel(.object(fileLabel: imageFileLabel, object: object), iconSize: config.iconSize),
                    config: config)
        }
    }
}
