
import Foundation
import ChangeResolvers
import ServerShared
protocol ItemType {
    // SyncServer objectType
    static var objectType: String {get}
    var objectType: String {get}
    
    // For this object type, to display in the UI.
    var displayName: String {get}
    
    // For this object type, the article term prefix to display in the UI. e.g., "an" for "an image".
    var displayNameArticle: String {get}
    
    static func createNewFile(for fileLabel: String, mimeType: MimeType?) throws -> URL
}

extension ItemType {
    var objectType: String {
        return Self.objectType
    }
    
    static var filenamePrefix: String {
        return "Neebla"
    }
    
    static var commentFilenameExtension: String {
        return "json"
    }
}

