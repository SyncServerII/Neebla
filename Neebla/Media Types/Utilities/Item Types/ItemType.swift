
import Foundation
import ChangeResolvers
import ServerShared
import iOSShared

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
}

enum ItemTypeFiles {
    static let filenamePrefix = "Neebla"
    static let commentFilenameExtension = "json"
    static let mediaItemAttributesFilenameExtension = "json"
    
    static func createNewMediaItemAttributesFile() throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        return try Files.createTemporary(withPrefix: Self.filenamePrefix, andExtension: Self.mediaItemAttributesFilenameExtension, inDirectory: localObjectsDir)
    }
    
    static func createNewCommentFile() throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        return try Files.createTemporary(withPrefix: Self.filenamePrefix, andExtension: Self.commentFilenameExtension, inDirectory: localObjectsDir)
    }
}

