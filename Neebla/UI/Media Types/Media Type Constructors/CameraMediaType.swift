
import Foundation
import SwiftUI

struct CameraMediaType: MediaConstructorType {
    let uiDisplayName = "Camera"
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    
    let cameraAvailable:Bool
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage) {
        self.sharingGroupUUID = sharingGroupUUID
        cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        self.alertMessage = alertMessage
    }

    var body: some View {
        MediaTypeButton(mediaType: self) {
            isImagePickerDisplay = true
        }
        .enabled(cameraAvailable)
        .sheet(isPresented: $isImagePickerDisplay) {
            ImagePickerView(selectedImage: $selectedImage, sourceType: sourceType)
        }
    }
}
