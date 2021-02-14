
import SwiftUI
import ServerShared
import iOSShared
import PhotosUI

enum ImageType: String {
    case jpeg
    case heic
}
    
class LiveImageItemProvider: SXItemProvider {
    enum LiveImageItemProviderError: Error, BadAspectRatio {
        case cannotGetLivePhoto
        case failedCreatingURL
        case couldNotGetImage
        case bizzareWrongType
        case couldNotConvertToJPEG
        case badAspectRatio
        
        var isBadAspectRatio: Bool {
            if case .badAspectRatio = self {
                return true
            }
            else {
                return false
            }
        }
    }
    
    // This is what I see in the sharing extension
    static let livePhotoUTI = "com.apple.live-photo"
    
    // This is what I see in the main app.
    static let livePhotoBundleUTI = "com.apple.live-photo-bundle"
    
    static let movieUTI = "com.apple.quicktime-movie"
    static let heicUTI = "public.heic"
    static let jpegUTI = "public.jpeg"
    
    var assets: UploadableMediaAssets {
        return liveImageAssets
    }

    private let liveImageAssets: LiveImageObjectTypeAssets
    
    required init(assets: LiveImageObjectTypeAssets) {
        self.liveImageAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        let conformsToImage = item.hasItemConformingToTypeIdentifier(jpegUTI) || item.hasItemConformingToTypeIdentifier(heicUTI)
        
        let conformsToLivePhotoUTI = item.hasItemConformingToTypeIdentifier(livePhotoUTI)
        let conformsToLivePhotoBundleUTI = item.hasItemConformingToTypeIdentifier(livePhotoBundleUTI)
        
        let conformsToLivePhoto = conformsToLivePhotoUTI || conformsToLivePhotoBundleUTI
        
        // `canLoadObject` is returning false in sharing extension. Check for it here.
        let canLoadObject = item.canLoadObject(ofClass: PHLivePhoto.self)
        
        let canHandle = conformsToImage && conformsToLivePhoto && canLoadObject
        
        logger.debug("conformsToLivePhotoUTI: \(conformsToLivePhotoUTI)")
        logger.debug("conformsToLivePhotoBundleUTI: \(conformsToLivePhotoBundleUTI)")
        logger.debug("canLoadObject: \(canLoadObject)")
        logger.debug("canHandle: \(canHandle)")
        logger.debug("registeredTypeIdentifiers: \(item.registeredTypeIdentifiers)")
        
        return canHandle
    }
    
    static func create(item: NSItemProvider, completion: @escaping (Result<SXItemProvider, Error>) -> ()) -> Any? {
        _ = getMediaAssets(item: item) { result in
            switch result {
            case .success(let assets):
                guard let assets = assets as? LiveImageObjectTypeAssets else {
                    // Should *not* get here. Just for safekeeping.
                    completion(.failure(LiveImageItemProviderError.bizzareWrongType))
                    return
                }
                
                let obj = Self.init(assets: assets)
                completion(.success(obj))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        return nil
    }
    
    // I'm having problems using this from the sharing extension. canLoadObject and loadObject are failing. This is when running the Sharing Extension target using the simulator. Behaving the same way when running on an actual device. See also https://developer.apple.com/forums/thread/22132?login=true
    // And https://stackoverflow.com/questions/33247240/error-accessing-live-photo-from-app-extension
    // And possibly https://stackoverflow.com/questions/39422917/get-video-from-share-extension-from-photos-like-whatsapp
    // Posted my own question: https://stackoverflow.com/questions/65470983/getting-a-live-image-phlivephoto-when-in-a-sharing-extension-using-the-photos
    // item.loadFileRepresentation(forTypeIdentifier: Self.movieUTI) is also failing with `No appropriate representation found for type com.apple.quicktime-movie`
    
    static func getMediaAssets(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {
        
        guard item.canLoadObject(ofClass: PHLivePhoto.self) else {
            logger.error("Could not load PHLivePhoto")
            completion(.failure(LiveImageItemProviderError.cannotGetLivePhoto))
            return nil
        }
        
        item.loadObject(ofClass: PHLivePhoto.self) { livePhoto, error in
            guard let livePhoto = livePhoto as? PHLivePhoto else {
                logger.debug("No live photo: \(String(describing: error))")
                completion(.failure(LiveImageItemProviderError.cannotGetLivePhoto))
                return
            }
            
            let assetResources = PHAssetResource.assetResources(for: livePhoto)
            guard assetResources.count == 2 else {
                completion(.failure(LiveImageItemProviderError.cannotGetLivePhoto))
                return
            }
            
            let filteredForMovie = assetResources.filter {$0.uniformTypeIdentifier == movieUTI}

            guard filteredForMovie.count == 1 else {
                logger.error("Could not find movie resource: \(movieUTI)")
                completion(.failure(LiveImageItemProviderError.cannotGetLivePhoto))
                return
            }
            
            let movie:PHAssetResource = filteredForMovie[0]
            
            let filteredForOther = assetResources.filter {$0 !== movie}
            
            guard filteredForOther.count == 1 else {
                logger.error("Could not find other resource")
                completion(.failure(LiveImageItemProviderError.cannotGetLivePhoto))
                return
            }
            let image: PHAssetResource = filteredForOther[0]

            let pickedImageType: ImageType
            
            switch image.uniformTypeIdentifier {
            case heicUTI:
                pickedImageType = .heic
            case jpegUTI:
                pickedImageType = .jpeg
            default:
                logger.error("UTI for image wasn't known.")
                completion(.failure(LiveImageItemProviderError.cannotGetLivePhoto))
                return
            }
            
            logger.debug("assetResources: \(assetResources.count)")

            let movieFile:URL
            let imageFile:URL
            let filePrefix = "live"
            
            let tempDir = Files.getDocumentsDirectory().appendingPathComponent( LocalFiles.temporary)
            
            do {
                movieFile = try Files.createTemporary(withPrefix: filePrefix, andExtension: "mov", inDirectory: tempDir, create: false)
                imageFile = try Files.createTemporary(withPrefix: filePrefix, andExtension: pickedImageType.rawValue, inDirectory: tempDir, create: false)
            } catch let error {
                logger.error("Could not create url: error: \(error)")
                completion(.failure(LiveImageItemProviderError.failedCreatingURL))
                return
            }
            
            PHAssetResourceManager.default().writeData(for: movie, toFile: movieFile, options: nil) { error in
                if let error = error {
                    logger.error("Could not write movie file: \(movieFile); error: \(error)")
                    completion(.failure(LiveImageItemProviderError.couldNotGetImage))
                    return
                }
                
                logger.debug("Wrote movie file to: \(movieFile)")
                
                PHAssetResourceManager.default().writeData(for: image, toFile: imageFile, options: nil) { error in
                    if let error = error {
                        logger.error("Could not write image file: \(imageFile); error: \(error)")
                        completion(.failure(LiveImageItemProviderError.couldNotGetImage))
                        return
                    }
                    
                    guard let size = UIImage.size(of: imageFile), size.aspectRatioOK() else {
                        completion(.failure(SXItemProviderError.badAspectRatio))
                        return
                    }
                    
                    let assets: LiveImageObjectTypeAssets
                    
                    // If image isn't a jpeg, convert it.
                    switch pickedImageType {
                    case .heic:
                        let jpegImageFile: URL
                        do {
                            jpegImageFile = try Files.createTemporary(withPrefix: filePrefix, andExtension: ImageType.jpeg.rawValue, inDirectory: tempDir, create: false)
                            try LiveImageObjectType.convertHEICImageToJPEG(heicURL: imageFile, outputJPEGImageURL: jpegImageFile)
                            assets = LiveImageObjectTypeAssets(imageFile: jpegImageFile, movieFile: movieFile)
                        } catch let error {
                            logger.error("\(error)")
                            completion(.failure(LiveImageItemProviderError.couldNotConvertToJPEG))
                            return
                        }
                        
                    case .jpeg:
                        assets = LiveImageObjectTypeAssets(imageFile: imageFile, movieFile: movieFile)
                    }

                    completion(.success(assets))
                }
            }
        }
        
        return nil
    }

    func preview(for config: IconConfig) -> AnyView {
        return AnyView(
            LiveImageIcon(.url(liveImageAssets.imageFile), config: config)
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try LiveImageObjectType.uploadNewObjectInstance(assets: liveImageAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
