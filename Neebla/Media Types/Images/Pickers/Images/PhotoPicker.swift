
import Foundation
import SwiftUI
import PhotosUI
import iOSShared

// This supports still images and live photos, both selected from the library. (Right now, we can't upload a live image directly from the camera).

// See https://medium.com/dev-genius/swiftui-how-to-use-phpicker-photosui-to-select-image-from-library-5b74885720ec
// https://developer.apple.com/forums/thread/651743
// https://arthurhammer.de/2020/08/iOS14-phpicker/
// https://github.com/LimitPoint/LivePhoto
// Using this https://github.com/OlegAba/LPLivePhotoGenerator I was able set some breakpoints, and pull out the live image formatted JPEG/MOV files, drag them into the iOS Simulator, and have a live photo in the simulator!
// Asked question here too:
// https://github.com/OlegAba/LPLivePhotoGenerator/issues/15

// https://github.com/timonus/UIImageHEIC

enum PhotoPickerError: Error {
    case failedCreatingURL
    case couldNotGetImage
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var isPresented
    var controller:PHPickerViewController!
    
    var configuration: PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .any(of: [.livePhotos, .images, .videos])
        config.selectionLimit = 1
        
        return config
    }
    let completion:(Result<UploadableMediaAssets, Error>)->()
    
    // Completion handler is called back on the main thread.
    init(completion:@escaping (Result<UploadableMediaAssets, Error>)->()) {
        self.completion = completion
        controller = PHPickerViewController(configuration: configuration)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Use a Coordinator to act as your PHPickerViewControllerDelegate
    class Coordinator: PHPickerViewControllerDelegate {
        let spinner = UIActivityIndicatorView(style: .large)

        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
        var progress:Progress?
      
        private let parent: PhotoPicker
        let itemProviderFactory = ItemProviderFactory()
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        private func addSpinner() {
            guard spinner.superview == nil else {
                spinner.startAnimating()
                return
            }
            
            spinner.translatesAutoresizingMaskIntoConstraints = false
            
            guard let view = parent.controller.view else {
                return
            }
            
            view.addSubview(spinner)
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            spinner.startAnimating()
        }
        
        // This gets called on a cancel, and when finished picking.
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
            if results.count == 0 {
                // User tapped cancel.
                parent.isPresented.wrappedValue.dismiss()
                return
            }

            // Only allowing user to pick a single image for now.
            guard results.count == 1 else {
                logger.error("More than one PHPickerResult!")
                return
            }
            
            logger.debug("results: \(results)")
            
            let alert = UIAlertController(title: "Add media?", message: "Is this the media you want to add to the album?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
                self.addImage(result: results[0])
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            }))
            parent.controller.present(alert, animated: true)
        }
        
        private func addImage(result: PHPickerResult) {
            // Checking `authorizationStatus` because I want to allow for PHAsset.fetchAssets usage.
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                // Access has been granted.
                addImageAux(result: result)
            } else {
                PHPhotoLibrary.requestAuthorization{ newStatus in
                    if newStatus == .authorized {
                        self.addImageAux(result: result)
                    } else {
                        logger.error("User didn't authorize PHPhotoLibrary access.")
                        // Not going to fail. The fetchAssets is just used to improve performance. e.g., to get size of video.
                        self.addImageAux(result: result)
                    }
                }
            }
        }
        
        // TODO: Not reporting errors properly from this. I tried putting an .alert on this picker, but didn't get that working.
        // See https://docs.google.com/document/d/190FBElJHbzCqvI9-pZGuHOg4jC2gbMh3lB6INCaiQcs/edit#bookmark=id.m29y98rl7vw8
        private func addImageAux(result: PHPickerResult) {
            addSpinner()
            
            let spec = ItemSpecification(assetIdentifier: result.assetIdentifier, item: result.itemProvider)
            
            itemProviderFactory.create(using: [spec]) { [weak self] result in
                guard let self = self else { return }
                
                self.spinner.stopAnimating()
                
                switch result {
                case .success(let itemProvider):
                    logger.debug("liveImage: pickedImage: \(itemProvider)")
                    DispatchQueue.main.async {
                        self.parent.completion(.success(itemProvider.assets))
                        self.parent.isPresented.wrappedValue.dismiss()
                    }
                    
                case .failure(let error):
                    logger.error("error: \(error)")
                    if let displayableError = error as? UserDisplayable,
                        let displayable = displayableError.userDisplayableMessage {
                        self.parent.showError(title: displayable.title, message: displayable.message)
                    }
                    else {
                        self.parent.showError(title: "Alert!", message: "Could not add that media.")
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        DispatchQueue.main.async {
            controller?.present(alert, animated: true)
        }
    }
}
