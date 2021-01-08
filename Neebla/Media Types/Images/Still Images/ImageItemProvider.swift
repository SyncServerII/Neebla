
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
            return getMediaAsset(item: item, mimeType: .jpeg, typeIdentifier: jpegUTI, completion: completion)
        }
        else if item.hasItemConformingToTypeIdentifier(pngUTI) {
            return getMediaAsset(item: item, mimeType: .png, typeIdentifier: pngUTI, completion: completion)
        }
        
        // Shouldn't get here.
        return nil
    }
    
    private static func getMediaAsset(item: NSItemProvider, mimeType: MimeType, typeIdentifier: String, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
        item.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { (url, error) in
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
                imageFileCopy = try Files.createTemporary(withPrefix: "image", andExtension: mimeType.fileNameExtension, inDirectory: tempDir, create: false)
                try FileManager.default.copyItem(at: url, to: imageFileCopy)
            } catch let error {
                logger.error("\(error)")
                completion(.failure(ImageItemProviderError.cannotGetImage))
                return
            }
                
            do {
                let assets = try ImageObjectTypeAssets(mimeType: mimeType, imageURL: imageFileCopy)
                completion(.success(assets))
            }
            catch let error {
                logger.error("\(error)")
                completion(.failure(ImageItemProviderError.cannotGetImage))
            }
        }
        
        return nil
    }
    
    var preview: AnyView {
        AnyView(
            GenericImageIcon(.url(imageAssets.imageURL))
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try ImageObjectType.uploadNewObjectInstance(assets: imageAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
