
import Foundation
import SwiftUI

struct LiveImageLargeMedia: View {
    let object:ServerObjectModel
    // @State var checked: Bool = false
    let tapOnLargeMedia: ()->()
    let model:LiveImageViewModel

    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
        self.object = object
        self.tapOnLargeMedia = tapOnLargeMedia
        model = LiveImageViewModel(fileGroupUUID: object.fileGroupUUID)
    }
    
    var body: some View {
        VStack {
            if model.gone {
                GoneImage()
            }
            else {
                ZoomableScrollView {
                    LiveImageView(model: model)
                }
            }
        }
        .onTapGesture {
            tapOnLargeMedia()
        }
        
//        HStack {
//            Spacer()
//            CheckBoxView(checked: $checked, text: "Repeat")
//        }
    }
}
