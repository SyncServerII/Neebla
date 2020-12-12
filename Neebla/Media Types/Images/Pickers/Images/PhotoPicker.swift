
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
    let completion:(Result<PickedImage, Error>)->()
    
    // Completion handler is called back on the main thread.
    init(isPresented:Binding<Bool>, completion:@escaping (Result<PickedImage, Error>)->()) {
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
            
            // I'm going to get a live image first-- because I think I'll be able to get a jpeg image from a live image in some cases. And don't want to always default to jpeg in those cases.
            tryToGetLiveImage(result: result) { [weak self] image in
                guard let self = self else { return }
                
                switch image {
                case .success(let pickedImage):
                    logger.debug("liveImage: pickedImage: \(pickedImage)")
                    DispatchQueue.main.async {
                        self.parent.isPresented = false
                        self.parent.completion(image)
                    }
                    
                case .failure:
                    self.tryToGetImage(result: result) { image in
                        switch image {
                        case .success(let pickedImage):
                            logger.debug("image: pickedImage: \(pickedImage)")
                            
                        case .failure(let error):
                            logger.error("error: \(error)")
                        }
                        
                        DispatchQueue.main.async {
                            self.parent.isPresented = false
                            self.parent.completion(image)
                        }
                    }
                }
            }
        }
        
        func tryToGetImage(result: PHPickerResult, completion:@escaping (Result<PickedImage, Error>)->()) {
            let imageIdentifier = "public.jpeg"
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: imageIdentifier) { [weak self] (url, error) in
                guard let self = self else { return }
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let url = url else {
                    completion(.failure(PhotoPickerError.couldNotGetImage))
                    return
                }
                
                // The file we get back isn't one we can do just anything with. E.g., we can't use the FileManager replaceItemAt method with it. Copy it.
                
                let imageFileCopy:URL
                do {
                    imageFileCopy = try Files.createTemporary(withPrefix: "image", andExtension: FilenameExtensions.jpegImage, inDirectory: self.tempDir, create: false)
                    try FileManager.default.copyItem(at: url, to: imageFileCopy)
                } catch let error {
                    logger.error("\(error)")
                    completion(.failure(PhotoPickerError.couldNotGetImage))
                    return
                }
                    
                let assets = ImageObjectTypeAssets(jpegFile: imageFileCopy)
                completion(.success(.jpeg(assets: assets)))
            }
        }
        
        func tryToGetLiveImage(result: PHPickerResult, completion:@escaping (Result<PickedImage, Error>)->()) {
            let movieUTI = "com.apple.quicktime-movie"
            let heicUTI = "public.heic"
            let jpegUTI = "public.jpeg"
            
            let itemProvider = result.itemProvider
            if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
                    guard let self = self else { return }
                    
                    if let livePhoto = livePhoto as? PHLivePhoto {
                        let assetResources = PHAssetResource.assetResources(for: livePhoto)
                        guard assetResources.count == 2 else {
                            completion(.failure(PhotoPickerError.couldNotGetImage))
                            return
                        }
                        
                        let filteredForMovie = assetResources.filter {$0.uniformTypeIdentifier == movieUTI}

                        guard filteredForMovie.count == 1 else {
                            logger.error("Could not find movie resource: \(movieUTI)")
                            completion(.failure(PhotoPickerError.couldNotGetImage))
                            return
                        }
                        
                        let movie:PHAssetResource = filteredForMovie[0]
                        
                        let filteredForOther = assetResources.filter {$0 !== movie}
                        
                        guard filteredForOther.count == 1 else {
                            logger.error("Could not find other resource")
                            completion(.failure(PhotoPickerError.couldNotGetImage))
                            return
                        }
                        let image: PHAssetResource = filteredForOther[0]

                        let pickedImageType: LiveImageObjectTypeAssets.ImageType
                        
                        switch image.uniformTypeIdentifier {
                        case heicUTI:
                            pickedImageType = .heic
                        case jpegUTI:
                            pickedImageType = .jpeg
                        default:
                            logger.error("UTI for image wasn't known.")
                            completion(.failure(PhotoPickerError.couldNotGetImage))
                            return
                        }
                        
                        logger.debug("assetResources: \(assetResources.count)")
                        

                            
                        let movieFile:URL
                        let imageFile:URL
                        let filePrefix = "live"
                        
                        do {
                            movieFile = try Files.createTemporary(withPrefix: filePrefix, andExtension: "mov", inDirectory: self.tempDir, create: false)
                            imageFile = try Files.createTemporary(withPrefix: filePrefix, andExtension: pickedImageType.rawValue, inDirectory: self.tempDir, create: false)
                        } catch let error {
                            logger.error("Could not create url: error: \(error)")
                            completion(.failure(PhotoPickerError.failedCreatingURL))
                            return
                        }
                        
                        PHAssetResourceManager.default().writeData(for: movie, toFile: movieFile, options: nil) { error in
                            if let error = error {
                                logger.error("Could not write movie file: \(movieFile); error: \(error)")
                                completion(.failure(PhotoPickerError.couldNotGetImage))
                                return
                            }
                            
                            logger.debug("Wrote movie file to: \(movieFile)")
                            
                            PHAssetResourceManager.default().writeData(for: image, toFile: imageFile, options: nil) { error in
                                if let error = error {
                                    logger.error("Could not write image file: \(imageFile); error: \(error)")
                                    completion(.failure(PhotoPickerError.couldNotGetImage))
                                    return
                                }
                                
                                let assets = LiveImageObjectTypeAssets(imageFile: imageFile, imageType: pickedImageType, movieFile: movieFile)
                                
                                completion(.success(.liveImage(assets: assets)))
                            }
                        }
                    } else {
                        logger.debug("No live photo!")
                        completion(.failure(PhotoPickerError.couldNotGetImage))
                    }
                }
            }
            else {
                print("Could not load PHLivePhoto")
                completion(.failure(PhotoPickerError.couldNotGetImage))
            }
        }
    }
}
