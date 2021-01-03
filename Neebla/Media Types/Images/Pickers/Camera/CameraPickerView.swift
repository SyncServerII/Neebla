import UIKit
import SwiftUI
import AVFoundation
import Foundation
import PhotosUI
import MobileCoreServices
import iOSShared

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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.picker.isPresented.wrappedValue.dismiss()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent( LocalFiles.temporary)
        
        let tempImageFile: URL
        do {
            tempImageFile = try Files.createTemporary(withPrefix: "temp", andExtension: FilenameExtensions.jpegImage, inDirectory: tempDir, create: false)
        } catch let error {
            logger.error("Could not create new file for image: \(error)")
            return
        }
        
        let jpegQuality: CGFloat
        do {
            jpegQuality = try SettingsModel.jpegQuality(db: Services.session.db)
        } catch let error {
            logger.error("Could not get settings: \(error)")
            return
        }
        
        guard let data = selectedImage.jpegData(compressionQuality: jpegQuality) else {
            logger.error("Could not get jpeg data for image.")
            return
        }
        
        do {
            try data.write(to: tempImageFile)
        } catch let error {
            logger.error("Could not write image file: \(error)")
            return
        }
                
        let asset = ImageObjectTypeAssets(jpegFile: tempImageFile)
        self.picker.picked(asset)
        self.picker.isPresented.wrappedValue.dismiss()
    }
}
