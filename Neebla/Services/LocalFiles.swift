
import Foundation
import iOSShared

struct LocalFiles {
    // These are within the app's Documents directory
    static let syncServerDatabase = "SyncServer.SQLite.db"
    static let neeblaDatabase = "Neebla.SQLite.db"
    
    // Files composing objects are located in this directory in the Documents directory.
    static let objectsDir = "objects"
    
    // Directory containing images scaled from large images in the objects directory.
    // Created at app launch if it doesn't exist.
    static let icons = "icons"
    
    static func setup() throws {
        let iconsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.icons)
        try Files.createDirectoryIfNeeded(iconsDir)
    }
}
