
import Foundation
import SwiftUI
import ServerShared

// Sharing Extension Item Provider protocol

protocol SXItemProvider: ItemProvider {
    // Don't use the `getMediaAssets` method from ItemProvider any more. Use this.
    static func create(item: NSItemProvider, completion:@escaping (Result<SXItemProvider, Error>)->())
    
    var preview: AnyView { get }
    func upload(toAlbum sharingGroupUUID: UUID) throws
}
