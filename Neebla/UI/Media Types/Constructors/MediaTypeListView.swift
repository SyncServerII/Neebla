
import Foundation
import SwiftUI

protocol MediaConstructorBasics {
    var uiDisplayName: String {get}
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage)
}

protocol MediaConstructorView: MediaConstructorBasics {
    var constructor: AnyView {get}
}

struct MediaTypeListView: View {
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
    }
    
    var body: some View {
        List {
            CameraMediaType(album: sharingGroupUUID, alertMessage: alertMessage)
            PhotoLibraryMediaType(album: sharingGroupUUID, alertMessage: alertMessage)
            WebLinkMediaType(album: sharingGroupUUID, alertMessage: alertMessage)
        }
    }
}
