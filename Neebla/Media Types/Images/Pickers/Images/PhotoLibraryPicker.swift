
import Foundation
import SwiftUI
import iOSShared

struct PhotoLibraryPicker: MediaConstructorBasics, View {
    let uiDisplayName = "Photo library image"
    let model:PhotoLibraryPickerModel
    let dismisser:MediaTypeListDismisser
    
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    
    init(album sharingGroupUUID: UUID, dismisser:MediaTypeListDismisser) {
        self.dismisser = dismisser
        self.model = PhotoLibraryPickerModel(album: sharingGroupUUID, dismisser: dismisser)
    }
    
    var body: some View {
        MediaTypeButton(mediaType: self) {
            isImagePickerDisplay = true
        }
        .sheet(isPresented: $isImagePickerDisplay) {
            PhotoPicker(isPresented: $isImagePickerDisplay, dismisser: dismisser) { result in
                model.uploadImage(pickerResult: result)
            }
        }
    }
}
