
import Foundation

protocol ItemProvider {
    var assets: UploadableMediaAssets { get}
    
    // If the provider returns true from this, then use the constructor to make an instance. Sometimes `canHandle` may return a false positive-- returning true, but failing to create an instance.
    static func canHandle(item: NSItemProvider) -> Bool
    
    // Retain the returned handle, if non-nil, until the completion handler is called.
    static func getMediaAssets(item: NSItemProvider, completion:@escaping (Result<UploadableMediaAssets, Error>)->()) -> Any?
}
