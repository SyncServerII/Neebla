
import Foundation
import SwiftUI
import iOSShared

struct PhotoLibraryPicker: MediaConstructorBasics, View {
    let uiDisplayName = "Photo library image"
    let model:PhotoLibraryPickerModel
    
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        self.model = PhotoLibraryPickerModel(album: sharingGroupUUID, alertMessage: alertMessage, dismisser: dismisser)
    }
    
    var body: some View {
        MediaTypeButton(mediaType: self) {
            isImagePickerDisplay = true
        }
        .sheet(isPresented: $isImagePickerDisplay) {
            PhotoPicker(isPresented: $isImagePickerDisplay) { result in
                model.uploadImage(pickerResult: result)
            }
        }
    }
}
