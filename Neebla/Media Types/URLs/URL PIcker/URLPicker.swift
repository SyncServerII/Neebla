
import Foundation
import SwiftUI
import SMLinkPreview

struct URLPicker: MediaConstructorBasics, View {
    let uiDisplayName = "Web link (URL)"
    @State private var isPickerDisplay = false
    @State var linkMedia: URLObjectTypeAssets?
    let model: URLPickerModel
    
    init(album sharingGroupUUID: UUID, dismisser:MediaTypeListDismisser) {
        model = URLPickerModel(album: sharingGroupUUID, dismisser: dismisser)
    }
    
    var body: some View {
        MediaTypeButton(mediaType: self) {
            isPickerDisplay = true
        }
        .sheet(isPresented: $isPickerDisplay) {
            URLPickerView() { pickedURL in
                model.upload(assets: pickedURL)
            }
        }
    }
}
