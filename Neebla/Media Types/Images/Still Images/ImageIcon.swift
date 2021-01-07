
import Foundation
import SwiftUI

struct ImageIcon: View {
    let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel
    let object: ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    var body: some View {
        GenericImageIcon(.object(fileLabel: imageFileLabel, object: object))
    }
}
