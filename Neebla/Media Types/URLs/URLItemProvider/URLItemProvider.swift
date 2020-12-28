
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

    private let urlAssets: URLObjectTypeAssets

    enum URLItemProviderError: Error {
        case bizzareWrongType
        case cannotGetURL
        case couldNotCreateURLPreviewGenerator
        case cannotGetLinkData
    }
    
    required init(assets: URLObjectTypeAssets) {
        self.urlAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        let canHandle = item.hasItemConformingToTypeIdentifier(urlUTI)
        logger.debug("canHandle: \(canHandle)")
        return canHandle
    }
    
    class URLItemProviderSupport {
        var generator: URLPreviewGenerator!
        var preview:LinkPreview!
    }
    
    static func getMediaAssets(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {        
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
    
    var preview: AnyView {
        return AnyView(
            URLPreviewItemProvider(linkData: urlAssets.linkData)
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try URLObjectType.uploadNewObjectInstance(asset: urlAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
