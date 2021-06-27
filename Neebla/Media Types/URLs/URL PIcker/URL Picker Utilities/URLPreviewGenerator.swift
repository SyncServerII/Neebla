
import Foundation
import SMLinkPreview
import iOSShared
import UIKit

class URLPreviewGenerator {
    enum URLPreviewGeneratorError: Error {
        case failedToGetPlistValue
        case failedToInitializePlugin
    }
    
    init() throws {
        PreviewManager.session.reset()
        PreviewManager.session.config = PreviewConfiguration()

        guard let requestKeyName = MicrosoftURLPreview.requestKeyName,
            let microsoftKey = APIKey.getFromPlist(plistKeyName: "MicrosoftURLPreview", requestKeyName: requestKeyName, plistName: "APIKeys") else {
            throw URLPreviewGeneratorError.failedToGetPlistValue
        }
        
        guard let msPreview = MicrosoftURLPreview(apiKey: microsoftKey) else {
            throw URLPreviewGeneratorError.failedToInitializePlugin
        }
        
        guard let adaPreview = AdaSupportPreview(apiKey: nil) else {
            throw URLPreviewGeneratorError.failedToInitializePlugin
        }
        
        guard let mPreview = MicrolinkPreview(apiKey: nil) else {
            throw URLPreviewGeneratorError.failedToInitializePlugin
        }

        PreviewManager.session.add(source: msPreview)
        PreviewManager.session.add(source: adaPreview)
        PreviewManager.session.add(source: mPreview)
    }
    
    func getPreview(for url: URL, completion: @escaping (LinkData?)->()) {
        // I'm going to require that the linkData have at least some content
        PreviewManager.session.linkDataFilter = { linkData in
            return linkData.description != nil ||
                linkData.icon != nil ||
                linkData.image != nil
        }
        
        PreviewManager.session.getLinkData(url: url) { linkData in
            logger.debug("linkData: \(String(describing: linkData))")
            completion(linkData)
        }
    }
}
