
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
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser)
}

struct MediaTypeListView: View {
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    let dismisser:MediaTypeListDismisser
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser: MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
        self.dismisser = dismisser
    }
    
    var body: some View {
        List {
            CameraMediaType(album: sharingGroupUUID, alertMessage: alertMessage, dismisser: dismisser)
            PhotoLibraryMediaType(album: sharingGroupUUID, alertMessage: alertMessage, dismisser: dismisser)
            WebLinkMediaType(album: sharingGroupUUID, alertMessage: alertMessage, dismisser: dismisser)
        }
    }
}
