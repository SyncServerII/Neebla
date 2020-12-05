
import Foundation

protocol ItemType {
    // SyncServer objectType
    static var objectType: String {get}
    var objectType: String {get}
    
    // For this object type, to display in the UI.
    var displayName: String {get}
    
    static func createNewFile(for fileLabel: String) throws -> URL
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

