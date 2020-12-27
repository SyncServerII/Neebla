
import Foundation

protocol ItemProvider {
    // If the provider returns true from this, then use the constructor to make an instance.
    static func canHandle(item: NSItemProvider) -> Bool
    
    // If `canHandle` reported `true`, then an errors are reported only for actual errors, not because this provider cannot handle this media type.
    static func getMediaAssets(item: NSItemProvider, completion:@escaping (Result<UploadableMediaAssets, Error>)->())
}
