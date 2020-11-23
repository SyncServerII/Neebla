
import Foundation
import SwiftUI

struct ImageIcon: View {
    let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel
    let object: ServerObjectModel
    @State var unusedShowingImage: Bool = false
    
    var body: some View {
        return GenericImageIcon(fileLabel: imageFileLabel, object: object, showingImage: $unusedShowingImage)
    }
}
