
import Foundation
import SwiftUI

struct LiveImageLargeMedia: View {
    let object:ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    var body: some View {
        ZoomableScrollView {
            LiveImageView(fileGroupUUID: object.fileGroupUUID)
        }
    }
}
