
import SwiftUI
import ServerShared
import iOSShared

class ImageItemProvider: SXItemProvider {
    // TODO: Extend this to dealing with PNG and possibly HEIC images. Not sure if a HEIC image can be the only one, but I've seen just a PNG.
    static let jpegUTI = "public.jpeg"

    enum ImageItemProviderError: Error {
        case cannotGetImage
        case bizzareWrongType
    }

    var assets: UploadableMediaAssets {
        return imageAssets
    }

    private let imageAssets: ImageObjectTypeAssets
    
    required init(assets: ImageObjectTypeAssets) {
        self.imageAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        return item.hasItemConformingToTypeIdentifier(jpegUTI)
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
