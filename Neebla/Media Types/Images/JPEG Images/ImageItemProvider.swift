
import SwiftUI
import ServerShared
import iOSShared

class ImageItemProvider: SXItemProvider {
    // TODO: Extend this to dealing with HEIC images.
    static let jpegUTI = "public.jpeg"
    static let pngUTI = "public.png"

    enum ImageItemProviderError: Error {
        case cannotGetImage
        case bizzareWrongType
        case couldNotConvertToJPEG
    }

    var assets: UploadableMediaAssets {
        return imageAssets
    }

    private let imageAssets: ImageObjectTypeAssets
    
    required init(assets: ImageObjectTypeAssets) {
        self.imageAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        return item.hasItemConformingToTypeIdentifier(jpegUTI) || item.hasItemConformingToTypeIdentifier(pngUTI)
    }

    static func create(item: NSItemProvider, completion:@escaping (Result<SXItemProvider, Error>)->()) -> Any? {
        _ = getMediaAssets(item: item) { result in
            switch result {
            case .success(let assets):
                guard let assets = assets as? ImageObjectTypeAssets else {
                    // Should *not* get here. Just for safekeeping.
                    completion(.failure(ImageItemProviderError.bizzareWrongType))
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

    static func getMediaAssets(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {

        if item.hasItemConformingToTypeIdentifier(jpegUTI) {
            return getJPEGMediaAsset(item: item, completion: completion)
        }
        else if item.hasItemConformingToTypeIdentifier(pngUTI) {
            return getPNGMediaAsset(item: item, completion: completion)
        }
        
        // Shouldn't get here.
        return nil
    }
 
    private static func getPNGMediaAsset(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
        item.loadFileRepresentation(forTypeIdentifier: Self.pngUTI) { (url, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
                        
            guard let url = url else {
                completion(.failure(ImageItemProviderError.cannotGetImage))
                return
            }
            
            // Neebla is only going to upload JPEG files to the server. Convert PNG to JPEG.
            let filePrefix = "formerPNG"

            let jpegImageFile:URL
            do {
                let pngImageData = try Data(contentsOf: url)
                guard let image = UIImage(data: pngImageData) else {
                    completion(.failure(ImageItemProviderError.couldNotConvertToJPEG))
                    return
                }
                                
                let jpegQuality = try SettingsModel.jpegQuality(db: Services.session.db)
                
                guard let jpegData = image.jpegData(compressionQuality: jpegQuality) else {
                    completion(.failure(ImageItemProviderError.couldNotConvertToJPEG))
                    return
                }

                jpegImageFile = try Files.createTemporary(withPrefix: filePrefix, andExtension: ImageType.jpeg.rawValue, inDirectory: tempDir, create: false)
                
                try jpegData.write(to: jpegImageFile)
            } catch let error {
                logger.error("\(error)")
                completion(.failure(ImageItemProviderError.couldNotConvertToJPEG))
                return
            }
                
            let assets = ImageObjectTypeAssets(jpegFile: jpegImageFile)
            completion(.success(assets))
        }
        
        return nil
    }
    
    private static func getJPEGMediaAsset(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
        item.loadFileRepresentation(forTypeIdentifier: Self.jpegUTI) { (url, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let url = url else {
                completion(.failure(ImageItemProviderError.cannotGetImage))
                return
            }
            
            // The file we get back isn't one we can do just anything with. E.g., we can't use the FileManager replaceItemAt method with it. Copy it.
            
            let imageFileCopy:URL
            do {
                imageFileCopy = try Files.createTemporary(withPrefix: "image", andExtension: FilenameExtensions.jpegImage, inDirectory: tempDir, create: false)
                try FileManager.default.copyItem(at: url, to: imageFileCopy)
            } catch let error {
                logger.error("\(error)")
                completion(.failure(ImageItemProviderError.cannotGetImage))
                return
            }
                
            let assets = ImageObjectTypeAssets(jpegFile: imageFileCopy)
            completion(.success(assets))
        }
        
        return nil
    }
    
    var preview: AnyView {
        AnyView(
            GenericImageIcon(.url(imageAssets.jpegFile))
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try ImageObjectType.uploadNewObjectInstance(assets: imageAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
