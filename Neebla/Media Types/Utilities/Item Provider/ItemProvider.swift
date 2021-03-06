
import Foundation

protocol ItemProvider {
    var assets: UploadableMediaAssets { get}
    
    // If the provider returns true from this, then use the constructor to make an instance.
    static func canHandle(item: NSItemProvider) -> Bool
    
    // If `canHandle` reported `true`, then an errors are reported only for actual errors, not because this provider cannot handle this media type.
    // Retain the returned handle, if non-nil, until the completion handler is called.
    static func getMediaAssets(item: NSItemProvider, completion:@escaping (Result<UploadableMediaAssets, Error>)->()) -> Any?
}
