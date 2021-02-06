
import SwiftUI
import ServerShared
import iOSShared
import PhotosUI
import SMLinkPreview

// This is not working in the sharing extension in Chrome:
// https://stackoverflow.com/questions/42911395/share-extension-google-chrome-not-working
// I updated the Info.plist so that <= 2 items are allowed and it's working now.

class URLItemProvider: SXItemProvider {
    var assets: UploadableMediaAssets {
        return urlAssets
    }
    
    // This is what I see in the sharing extension
    static let urlUTI = "public.url"

    // Doing a share operation in a particular way from Chrome, the only type identifier is: "public.plain-text"
    // Prefix was: bplist00 -- which seems to be a binary plist. See
    // https://stackoverflow.com/questions/65695606
    static let plainTextUTI = "public.plain-text"

    private let urlAssets: URLObjectTypeAssets

    enum URLItemProviderError: Error {
        case bizzareWrongType
        case cannotGetURL
        case couldNotCreateURLPreviewGenerator
        case cannotGetLinkData
        case cannotGetPlainTextURL
    }
    
    required init(assets: URLObjectTypeAssets) {
        self.urlAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        let canHandle = item.hasItemConformingToTypeIdentifier(urlUTI) ||
            item.hasItemConformingToTypeIdentifier(plainTextUTI)
        logger.debug("canHandle: \(canHandle); urlUTI: \(urlUTI); item.registeredTypeIdentifiers: \(item.registeredTypeIdentifiers)")
        return canHandle
    }
    
    // This will get retained by the caller-- so we can do async callbacks.
    class URLItemProviderSupport {
        var generator: URLPreviewGenerator!
        var preview:LinkPreview!
    }
    
    static func getMediaAssets(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {

        if item.hasItemConformingToTypeIdentifier(urlUTI) {
            return getMediaAssetsForURL(item: item, completion: completion)
        }
        else if item.hasItemConformingToTypeIdentifier(plainTextUTI) {
            return getMediaAssetsForBinaryPlist(item: item, completion: completion)
        }
        
        // Shouldn't get here.
        return nil
    }
    
    static func getMediaAssetsForURL(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {
        guard let generator = try? URLPreviewGenerator() else {
            completion(.failure(URLItemProviderError.couldNotCreateURLPreviewGenerator))
            return nil
        }
        
        let support = URLItemProviderSupport()
        support.generator = generator
                
        item.loadItem(forTypeIdentifier: Self.urlUTI, options: nil) { results, error in
            logger.debug("\(String(describing: results)); \(String(describing: error))")

            guard let url = results as? URL else {
                completion(.failure(URLItemProviderError.cannotGetURL))
                return
            }

            generator.getPreview(for: url) { linkData in
                guard let linkData = linkData else {
                    completion(.failure(URLItemProviderError.cannotGetURL))
                    return
                }

                support.preview = LinkPreview.create(with: linkData) { image in
                    completion(.success(URLObjectTypeAssets(linkData: linkData, image: image)))
                }
            }
        }
        
        return support
    }

    static func getMediaAssetsForBinaryPlist(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {

        guard let generator = try? URLPreviewGenerator() else {
            completion(.failure(URLItemProviderError.couldNotCreateURLPreviewGenerator))
            return nil
        }
        
        let support = URLItemProviderSupport()
        support.generator = generator
        
        item.loadDataRepresentation(forTypeIdentifier: plainTextUTI) { (data, error) in
            if let error = error {
                logger.error("\(error)")
                completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                return
            }

            guard let data = data else {
                logger.error("No data")
                completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                return
            }
            
            guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) else {
                logger.error("No data")
                completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                return
            }
            
            guard let dict = plist as? [String: Any] else {
                logger.error("No dict")
                completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                return
            }
                        
            guard let objects = dict["$objects"] else {
                logger.error("No objects")
                completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                return
            }
            
            guard let array = objects as? [String] else {
                logger.error("No objects")
                completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                return
            }
            
            for element in array {
                if element.hasPrefix("http") {
                    logger.debug("URL: \(element)")
                    
                    guard let url = URL(string: element) else {
                        completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                        return
                    }
                    
                    generator.getPreview(for: url) { linkData in
                        guard let linkData = linkData else {
                            completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
                            return
                        }

                        support.preview = LinkPreview.create(with: linkData) { image in
                            completion(.success(URLObjectTypeAssets(linkData: linkData, image: image)))
                        }
                    }
                    
                    return
                }
            } // end-for
            
            completion(.failure(URLItemProviderError.cannotGetPlainTextURL))
        }
        
        return support
    }
    
    static func create(item: NSItemProvider, completion: @escaping (Result<SXItemProvider, Error>) -> ()) -> Any? {
        let handle = getMediaAssets(item: item) { result in
            switch result {
            case .success(let assets):
                guard let assets = assets as? URLObjectTypeAssets else {
                    // Should *not* get here. Just for safekeeping.
                    completion(.failure(URLItemProviderError.bizzareWrongType))
                    return
                }
                
                let obj = Self.init(assets: assets)
                completion(.success(obj))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        return handle
    }
    
    func preview(for config: IconConfig) -> AnyView {
        return AnyView(
            URLPreviewItemProvider(linkData: urlAssets.linkData)
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try URLObjectType.uploadNewObjectInstance(asset: urlAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
