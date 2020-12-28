
import SwiftUI
import ServerShared
import iOSShared
import PhotosUI

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
    }
    
    required init(assets: URLObjectTypeAssets) {
        self.urlAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        let canHandle = item.hasItemConformingToTypeIdentifier(urlUTI)
        logger.debug("canHandle: \(canHandle)")
        return canHandle
    }
    
    static func getMediaAssets(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) {
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
        
        item.loadItem(forTypeIdentifier: Self.urlUTI, options: nil) { results, error in
            guard let url = results as? URL else {
                completion(.failure(URLItemProviderError.cannotGetURL))
                return
            }
            
            guard let generator = try? URLPreviewGenerator() else {
                completion(.failure(URLItemProviderError.couldNotCreateURLPreviewGenerator))
                return
            }
            
            generator.getPreview(for: url) { linkData in
                
            }
            
            logger.debug("\(String(describing: results)); \(String(describing: error))")
            completion(.failure(URLItemProviderError.cannotGetURL))
        }
    }
    
    static func create(item: NSItemProvider, completion: @escaping (Result<SXItemProvider, Error>) -> ()) {
        getMediaAssets(item: item) { result in
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
    }
    
    var preview: AnyView {
        return AnyView(
            Rectangle()
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
    }
}
