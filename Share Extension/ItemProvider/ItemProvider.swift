
import Foundation
import SwiftUI
import ServerShared

protocol ItemProvider {
    // Must have at least one type identifier from NSItemProvider. E.g. "public.jpeg"
    static var typeIdentifiers: [String] { get }
    
    init(url: URL) throws
    
    var mimeType: MimeType { get }
    
    var preview: AnyView { get }
    var itemURL: URL { get }
    
    // E.g., if uploading a very large file or a file that will change before uploading completes, set this to false.
    var shouldUploadCopy: Bool { get }
}
