
import SwiftUI
import ServerShared
import iOSShared

class ImageItemProvider: SXItemProvider {
    static let jpegUTI = "public.jpeg"
    static let pngUTI = "public.png"
    static let heicUTI = "public.heic"

    enum ImageItemProviderError: Error {
        case cannotGetImage
        case bizzareWrongType
        case couldNotConvertToJPEG
        case couldNotGetHEICData
        case couldNotConvertHEICToImage
        case couldNotGetSettings
    }

    var assets: UploadableMediaAssets {
        return imageAssets
    }

    private let imageAssets: ImageObjectTypeAssets
    
    required init(assets: ImageObjectTypeAssets) {
        self.imageAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        let canHandle = item.hasItemConformingToTypeIdentifier(jpegUTI) || item.hasItemConformingToTypeIdentifier(pngUTI) || item.hasItemConformingToTypeIdentifier(heicUTI)
        logger.debug("ImageItemProvider: canHandle: \(canHandle)")
        return canHandle
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
    
        /* Check HEIC first because in some cases I get registeredTypeIdentifiers: ["public.jpeg", "public.heic"] but I fail trying to load the JPEG.
        2021-01-22 19:51:57.439390-0700 Neebla[90625:6339733] Error copying file type public.jpeg. Error: Error Domain=NSItemProviderErrorDomain Code=-1000 "Cannot load representation of type public.jpeg" UserInfo={NSLocalizedDescription=Cannot load representation of type public.jpeg, NSUnderlyingError=0x600000108930 {Error Domain=NSCocoaErrorDomain Code=4101 "Couldn’t communicate with a helper application." UserInfo={NSUnderlyingError=0x6000001084e0 {Error Domain=PHAssetExportRequestErrorDomain Code=0 "(null)" UserInfo={NSUnderlyingE
        */
        if item.hasItemConformingToTypeIdentifier(heicUTI) {
            return getHEICAsset(item: item, completion: completion)
        }
        else if item.hasItemConformingToTypeIdentifier(jpegUTI) {
            return getMediaAsset(item: item, mimeType: .jpeg, typeIdentifier: jpegUTI, completion: completion)
        }
        else if item.hasItemConformingToTypeIdentifier(pngUTI) {
            return getMediaAsset(item: item, mimeType: .png, typeIdentifier: pngUTI, completion: completion)
        }

        // Shouldn't get here.
        return nil
    }

    // Handling HEIC separately because I don't want to upload these. They can be annoying for users, and I want representations in users cloud storage that are easy for people to deal with. So, convering from HEIC to JPEG.
    private static func getHEICAsset(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) {
        item.loadDataRepresentation(forTypeIdentifier: "public.heic") { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(ImageItemProviderError.couldNotGetHEICData))
                return
            }

            guard let image = UIImage(data: data) else {
                completion(.failure(ImageItemProviderError.couldNotConvertHEICToImage))
                return
            }
            
            guard image.size.isOK() else {
                completion(.failure(SXItemProviderError.badSize))
                return
            }

            guard let jpegQuality = try? SettingsModel.jpegQuality(db: Services.session.db) else {
                logger.error("Could not get settings.")
                completion(.failure(ImageItemProviderError.couldNotGetSettings))
                return
            }
            
            guard let jpegData = image.jpegData(compressionQuality: jpegQuality) else {
                completion(.failure(ImageItemProviderError.couldNotConvertToJPEG))
                return
            }

            let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
            let tempImageFile: URL
            do {
                tempImageFile = try Files.createTemporary(withPrefix: "temp", andExtension: MimeType.jpeg.fileNameExtension, inDirectory: tempDir, create: false)
                try jpegData.write(to: tempImageFile)
            } catch let error {
                logger.error("Could not create new file for image: \(error)")
                completion(.failure(ImageItemProviderError.cannotGetImage))
                return
            }
            
            do {
                let assets = try ImageObjectTypeAssets(mimeType: MimeType.jpeg, imageURL: tempImageFile)
                completion(.success(assets))
            }
            catch let error {
                logger.error("\(error)")
                completion(.failure(ImageItemProviderError.cannotGetImage))
            }
        }
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
            
            guard let size = UIImage.size(of: url), size.isOK() else {
                completion(.failure(SXItemProviderError.badSize))
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
    
    func preview(for config: IconConfig) -> AnyView {
        AnyView(
            GenericImageIcon(.url(imageAssets.imageURL), config: config)
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try ImageObjectType.uploadNewObjectInstance(assets: imageAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
