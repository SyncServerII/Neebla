
import Foundation
import SwiftUI

struct LiveImageLargeMedia: View {
    let object:ServerObjectModel
    // @State var checked: Bool = false
    let tapOnLargeMedia: ()->()

    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
        self.object = object
        self.tapOnLargeMedia = tapOnLargeMedia
    }
    
    var body: some View {
        ZoomableScrollView {
            LiveImageView(fileGroupUUID: object.fileGroupUUID)
                .onTapGesture {
                    tapOnLargeMedia()
                }
        }
        
//        HStack {
//            Spacer()
//            CheckBoxView(checked: $checked, text: "Repeat")
//        }
    }
}
