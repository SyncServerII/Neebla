
import Foundation
import SwiftUI
import SMLinkPreview

struct LinkMedia {
    let linkData: LinkData
    let image: LinkPreview.LoadedImage?
}

struct URLPicker: MediaConstructorBasics, View {
    let uiDisplayName = "Web link (URL)"
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    let dismisser:MediaTypeListDismisser
    @State private var isPickerDisplay = false
    @State var linkMedia: LinkMedia?

    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
        self.dismisser = dismisser
    }
    
    var body: some View {
        let selectedURLBinding = Binding<LinkMedia?>(get: {
            linkMedia
        }, set: {
            linkMedia = $0
            if let linkMedia = linkMedia {
                UploadURLObject.upload(linkMedia: linkMedia, sharingGroupUUID: sharingGroupUUID, alertMessage: alertMessage, dismisser: dismisser)
            }
        })
        
        return MediaTypeButton(mediaType: self) {
            isPickerDisplay = true
        }
        .sheet(isPresented: $isPickerDisplay) {
            URLPickerView(resultURL: selectedURLBinding)
        }
    }
}
