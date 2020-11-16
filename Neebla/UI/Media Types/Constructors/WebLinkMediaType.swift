
import Foundation
import SwiftUI

struct WebLinkMediaType: MediaConstructorView, View {
    let uiDisplayName = "Web link (URL)"
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    
    var constructor: AnyView {
        return AnyView(body)
    }
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
    }
    
    var body: some View {
        MediaTypeButton(mediaType: self) {
        }
    }
}
