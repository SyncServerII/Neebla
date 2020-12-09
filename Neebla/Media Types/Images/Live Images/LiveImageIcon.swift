
import Foundation
import SwiftUI

struct LiveImageIcon: View {
    let imageFileLabel = LiveImageObjectType.imageDeclaration.fileLabel
    let object: ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(fileLabel: imageFileLabel, object: object)
            TextInLowerRight(text: "live")
        }
    }
}
