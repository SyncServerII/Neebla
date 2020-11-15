
import Foundation
import SwiftUI

struct WebLinkMediaType: MediaType {
    let uiDisplayName = "Web link (URL)"
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
    }
    
    var body: some View {
        MediaTypeButton(mediaType: self) {
        }
    }
}
