
import Foundation
import SwiftUI
import ServerShared
import iOSShared

// Sharing Extension Item Provider

enum SXItemProviderError: Error, UserDisplayable {
    case badSize
    
    var userDisplayableMessage: (title: String, message: String)? {
        if self == .badSize {
            return SXItemProviderError.badSize
        }
        return nil
    }
}

protocol SXItemProvider: ItemProvider {
    // Don't use the `getMediaAssets` method from ItemProvider any more. Use this.
    // Returns a handle, that if non-nil, you need to keep a strong reference to until the completion handler returns.
    static func create(item: NSItemProvider, completion:@escaping (Result<SXItemProvider, Error>)->()) -> Any?
    
    func preview(for config: IconConfig) -> AnyView
    func upload(toAlbum sharingGroupUUID: UUID) throws
}
