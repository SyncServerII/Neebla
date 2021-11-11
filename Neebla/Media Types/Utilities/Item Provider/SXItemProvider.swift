
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

enum ItemProviderContent {
    case movie(URL)
    case image(UIImage)
}

struct ItemSpecification {
    let assetIdentifier: String?
    let item: NSItemProvider
}

protocol SXItemProvider: ItemProvider {
    // Don't use the `getMediaAssets` method from ItemProvider any more. Use this.
    // Returns a handle, that if non-nil, you need to keep a strong reference to until the completion handler returns.
    static func create(from: ItemSpecification, completion:@escaping (Result<SXItemProvider, Error>)->()) -> Any?
    
    func preview(for config: IconConfig) -> AnyView
    func upload(toAlbum sharingGroupUUID: UUID) throws
    
    // If nil is returned, that just means the provider couldn't create assets from the content. This method is optional. Not all providers need to have it.
    static func create(from content: ItemProviderContent) -> Result<UploadableMediaAssets, Error>?
}

extension SXItemProvider {
    static func create(from content: ItemProviderContent) -> Result<UploadableMediaAssets, Error>? {
        return nil
    }
}
