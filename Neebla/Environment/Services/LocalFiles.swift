
import Foundation
import iOSShared

struct LocalFiles {
    // This is within the app's Documents directory
    static let database = "SQLite.db"
    
    // Files composing objects are located in this directory in the Documents directory.
    static let objectsDir = "objects"
    
    // Directory containing images scaled from large images in the objects directory.
    // Created at app launch if it doesn't exist.
    static let icons = "icons"
    
    // Temporary directory for image picker and other purposes. Files are not removed automatically so far.
    static let temporary = "temp"
    
    // Directory for log files.
    static let loggingDir = "logging"
    
    // File in `loggingDir`
    static let loggingFile = "LogFile.txt"

    static func setup() throws {
        let loggingDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.loggingDir)
        try Files.createDirectoryIfNeeded(loggingDir)
        
        let iconsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.icons)
        try Files.createDirectoryIfNeeded(iconsDir)
        
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.temporary)
        try Files.createDirectoryIfNeeded(tempDir)
        
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        try Files.createDirectoryIfNeeded(localObjectsDir)
    }
}

extension LocalFiles {
    // For debugging
    static func numberOfFilesInObjectsDir() throws -> Int {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        let dirContents = try FileManager.default.contentsOfDirectory(atPath: localObjectsDir.path)
        return dirContents.count
    }
}
