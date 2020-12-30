
import Foundation
import SwiftUI
import SMLinkPreview

struct URLPicker: MediaConstructorBasics, View {
    let uiDisplayName = "Web link (URL)"
    @State private var isPickerDisplay = false
    @State var linkMedia: URLObjectTypeAssets?
    let model: URLPickerModel
    let dismisser:MediaTypeListDismisser
    
    init(album sharingGroupUUID: UUID, dismisser:MediaTypeListDismisser) {
        model = URLPickerModel(album: sharingGroupUUID, dismisser: dismisser)
        self.dismisser = dismisser
    }
    
    var body: some View {
        MediaTypeButton(mediaType: self) {
            isPickerDisplay = true
        }
        .sheet(isPresented: $isPickerDisplay) {
            URLPickerView(dismisser: dismisser) { pickedURL in
                model.upload(assets: pickedURL)
            }
        }
    }
}
