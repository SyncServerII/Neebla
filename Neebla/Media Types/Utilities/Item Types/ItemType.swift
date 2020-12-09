
import Foundation

protocol ItemType {
    // SyncServer objectType
    static var objectType: String {get}
    var objectType: String {get}
    
    // For this object type, to display in the UI.
    var displayName: String {get}
    
    static func createNewFile(for fileLabel: String) throws -> URL
}

enum FilenameExtensions {
    static var jpegImageFilename: String {
        return "jpeg"
    }
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
    
    static var jpegImageFilenameExtension: String {
        return FilenameExtensions.jpegImageFilename
    }
    
    static var quicktimeMovieFilenameExtension: String {
        return "mov"
    }
}

