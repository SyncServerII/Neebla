
import Foundation
import SwiftUI

struct LiveImageLargeMedia: View {
    let model:LiveImageViewModel
    let tapOnLargeMedia: ()->()
    
    // Separating this state from the model, to a `StateObject`, to ensure we only get a single initial playback of the live image.
    @StateObject var state = LiveImageViewState()

    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
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
                    LiveImageView(model: model, state: state)
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
