
import Foundation
import SwiftUI
import ServerShared

// Sharing Extension Item Provider

protocol BadAspectRatio: Error {
    var isBadAspectRatio: Bool {get}
}

enum SXItemProviderError: Error, BadAspectRatio {
    case badAspectRatio
    
    var isBadAspectRatio: Bool {
        return self == .badAspectRatio
    }
}

protocol SXItemProvider: ItemProvider {
    // Don't use the `getMediaAssets` method from ItemProvider any more. Use this.
    // Returns a handle, that if non-nil, you need to keep a strong reference to until the completion handler returns.
    static func create(item: NSItemProvider, completion:@escaping (Result<SXItemProvider, Error>)->()) -> Any?
    
    func preview(for config: IconConfig) -> AnyView
    func upload(toAlbum sharingGroupUUID: UUID) throws
}
