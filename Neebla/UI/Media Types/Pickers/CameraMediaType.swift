
import Foundation
import SwiftUI

struct CameraMediaType: MediaConstructorBasics, View {
    let uiDisplayName = "Camera"
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    let dismisser:MediaTypeListDismisser
    
    let cameraAvailable:Bool
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
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
        
        MediaTypeButton(mediaType: self) {
            isImagePickerDisplay = true
        }
        .enabled(cameraAvailable)
        .sheet(isPresented: $isImagePickerDisplay) {
            ImagePickerView(selectedImage: selectedImageBinding, sourceType: sourceType)
        }
    }
}
