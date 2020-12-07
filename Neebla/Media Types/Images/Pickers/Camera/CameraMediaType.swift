
import Foundation
import SwiftUI

// Can't use PHPickerViewController for camera
// See https://developer.apple.com/forums/thread/650748

struct CameraMediaType: MediaConstructorBasics, View {
    let uiDisplayName = "Camera image"
    let model: CameraMediaTypeModel
    let cameraAvailable:Bool
    @State private var isImagePickerDisplay = false
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        model = CameraMediaTypeModel(album: sharingGroupUUID, alertMessage: alertMessage, dismisser: dismisser)
    }

    var body: some View {
        MediaTypeButton(mediaType: self) {
            isImagePickerDisplay = true
        }
        .enabled(cameraAvailable)
        .sheet(isPresented: $isImagePickerDisplay) {
            CameraPickerView() { imageAsset in
                model.uploadImage(asset: imageAsset)
            }
        }
    }
}
