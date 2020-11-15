
import Foundation
import SwiftUI
import iOSShared

struct PhotoLibraryMediaType: MediaType {
    let uiDisplayName = "Photo Library"
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false

    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
    }
    
    var body: some View {
        let selectedImageBinding = Binding<UIImage?>(get: {
            selectedImage
        }, set: {
            selectedImage = $0
            uploadImage(image: $0)
        })
        
        return MediaTypeButton(mediaType: self) {
            isImagePickerDisplay = true
        }
        .sheet(isPresented: $isImagePickerDisplay) {
            ImagePickerView(selectedImage: selectedImageBinding, sourceType: sourceType)
        }
    }
    
    func uploadImage(image: UIImage?) {
        if let selectedImage = selectedImage {
            do {
                try ImageObjectType.uploadNewObjectInstance(image: selectedImage, sharingGroupUUID: sharingGroupUUID)
            } catch let error {
                logger.error("\(error)")
                alertMessage.alertMessage = "Could not upload new image!"
            }
        }
    }
}
