
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

#warning("TODO: Need to either filter as to not allow PNG's or include public.png in my still image processing. I just got a failure on an image selection due to this.")

enum PhotoPickerError: Error {
    case failedCreatingURL
    case couldNotGetImage
}

struct PhotoPicker: UIViewControllerRepresentable {
    var configuration: PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .any(of: [.livePhotos, .images])
        config.selectionLimit = 1
        
        return config
    }
    @Binding var isPresented: Bool
    let completion:(Result<UploadableMediaAssets, Error>)->()
    
    // Completion handler is called back on the main thread.
    init(isPresented:Binding<Bool>, completion:@escaping (Result<UploadableMediaAssets, Error>)->()) {
        self._isPresented = isPresented
        self.completion = completion
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Use a Coordinator to act as your PHPickerViewControllerDelegate
    class Coordinator: PHPickerViewControllerDelegate {
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
        var progress:Progress?
      
        private let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

            // Only allowing user to pick a single image for now.
            guard results.count == 1 else {
                logger.error("More than one PHPickerResult!")
                return
            }
            
            logger.debug("results: \(results)")
            
            let result = results[0]
            
            do {
                try ItemProviderFactory.create(using: result.itemProvider) { result in
                    switch result {
                    case .success(let itemProvider):
                        logger.debug("liveImage: pickedImage: \(itemProvider)")
                        DispatchQueue.main.async {
                            self.parent.isPresented = false
                            self.parent.completion(.success(itemProvider.assets))
                        }
                        
                    case .failure(let error):
                        logger.error("error: \(error)")
                        DispatchQueue.main.async {
                            self.parent.completion(.failure(error))
                        }
                    }
                }
            } catch let error {
                logger.error("error: \(error)")
                DispatchQueue.main.async {
                    self.parent.completion(.failure(error))
                }
            }
        }
    }
}
