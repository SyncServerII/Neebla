
import Foundation
import SwiftUI
import iOSShared

struct PhotoLibraryMediaType: MediaConstructorBasics, View {
    let uiDisplayName = "Photo library image"
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    let dismisser:MediaTypeListDismisser

    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
        self.dismisser = dismisser
    }
    
    var body: some View {
        let selectedImageBinding = Binding<UIImage?>(get: {
            selectedImage
        }, set: {
            selectedImage = $0
            if let selectedImage = selectedImage {
                UploadImageObject.upload(image: selectedImage, sharingGroupUUID: sharingGroupUUID, alertMessage: alertMessage, dismisser: dismisser)
            }
        })
        
        return MediaTypeButton(mediaType: self) {
            isImagePickerDisplay = true
        }
        .sheet(isPresented: $isImagePickerDisplay) {
            ImagePickerView(selectedImage: selectedImageBinding, sourceType: sourceType)
        }
    }
}
