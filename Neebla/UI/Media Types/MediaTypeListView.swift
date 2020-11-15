
import Foundation
import SwiftUI

protocol MediaType: View {
    var uiDisplayName: String {get}
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage)
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
