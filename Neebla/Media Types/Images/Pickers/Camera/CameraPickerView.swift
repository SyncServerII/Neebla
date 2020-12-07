import UIKit
import SwiftUI
import AVFoundation
import Foundation
import PhotosUI
import MobileCoreServices

// Using this only for camera.
// Adapted from https://medium.com/swlh/how-to-open-the-camera-and-photo-library-in-swiftui-9693f9d4586b

struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var isPresented
    let sourceType: UIImagePickerController.SourceType = .camera
    let picked: (ImageObjectTypeAssets) -> Void
    
    init(picked: @escaping (ImageObjectTypeAssets) -> Void) {
        self.picked = picked
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = self.sourceType
        imagePicker.mediaTypes = [kUTTypeLivePhoto as String, kUTTypeImage as String]
        imagePicker.allowsEditing = true
        imagePicker.delegate = context.coordinator // confirming the delegate
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    // Connecting the Coordinator class with this struct
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let picker: CameraPickerView

    init(picker: CameraPickerView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        let asset = ImageObjectTypeAssets(image: selectedImage)
        self.picker.picked(asset)
        self.picker.isPresented.wrappedValue.dismiss()
    }
}
