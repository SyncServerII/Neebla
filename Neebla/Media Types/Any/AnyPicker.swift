
import Foundation
import SwiftUI
import Combine

class MediaTypeListDismisser {
    var didDismiss: ((_ acquiredNewItem: Bool)->())?

    // acquiredNewItem: Was a new media item obtained? E.g., a new image.
    func dismiss(acquiredNewItem: Bool) {
        didDismiss?(acquiredNewItem)
    }
}

protocol MediaConstructorBasics {
    var uiDisplayName: String {get}
    init(album sharingGroupUUID: UUID, dismisser:MediaTypeListDismisser)
}

struct AnyPicker: View {
    let sharingGroupUUID: UUID
    let dismisser:MediaTypeListDismisser
    
    init(album sharingGroupUUID: UUID, dismisser: MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.dismisser = dismisser
    }
    
    var body: some View {
        VStack {
            // Note that this list doesn't map exactly to media types.
            // Some pickers allow upload of more than one media type. E.g., still images and live images by the PhotoLibraryPicker.
            // Multiple pickers are needed for some media types. E.g., PhotoLibraryPicker and CameraMediaType both support still images.
            
            CameraMediaType(album: sharingGroupUUID, dismisser: dismisser)
            Spacer().frame(height: 20)
            PhotoLibraryPicker(album: sharingGroupUUID, dismisser: dismisser)
            Spacer().frame(height: 20)
            URLPicker(album: sharingGroupUUID, dismisser: dismisser)
        }
    }
}
