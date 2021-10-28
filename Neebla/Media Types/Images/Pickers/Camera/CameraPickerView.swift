import UIKit
import SwiftUI
import AVFoundation
import Foundation
import PhotosUI
import MobileCoreServices
import iOSShared
import ServerShared

// Using this only for camera.
// Adapted from https://medium.com/swlh/how-to-open-the-camera-and-photo-library-in-swiftui-9693f9d4586b

struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var isPresented
    let sourceType: UIImagePickerController.SourceType = .camera
    let picked: (UploadableMediaAssets) -> Void
    
    init(picked: @escaping (UploadableMediaAssets) -> Void) {
        self.picked = picked
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = self.sourceType
        imagePicker.mediaTypes = [
            kUTTypeLivePhoto as String,
            kUTTypeImage as String,
            kUTTypeMovie as String
        ]
        
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
    let itemProviderFactory = ItemProviderFactory()

    init(picker: CameraPickerView) {
        self.picker = picker
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.picker.isPresented.wrappedValue.dismiss()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
        // Dealing with: a) image or b) video result.
        // For a movie, info[.originalImage] is nil; info[.mediaType] is "public.movie", and info[.mediaURL] has a URL for the movie. (Presumably a temporary URL that goes away after this delegate returns.)
        
        // From: https://developer.apple.com/documentation/uikit/uiimagepickercontroller/infokey/1619119-livephoto
        // When the user picks or captures a Live Photo, the editingInfo dictionary contains the livePhoto key, with a PHLivePhoto representation of the photo as the corresponding value.
        // However: I've not been able to get this working.
 
        let content: ItemProviderContent
        if let image = info[.originalImage] as? UIImage {
            content = .image(image)
        }
        else if info[.mediaType] as? String == "public.movie",
            let url = info[.mediaURL] as? URL {
            content = .movie(url)
        }
        else {
            logger.error("Could not get content")
            return
        }
        
        let result = itemProviderFactory.create(from: content)
        switch result {
        case .success(let assets):
            self.picker.picked(assets)
            self.picker.isPresented.wrappedValue.dismiss()
        case .failure(let error):
            logger.error("Could not get content: \(error)")
        }
    }
}
