
import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics

// Each represents a file component within a specific ServerObjectModel.

class ServerFileModel: DatabaseModel {
    let db: Connection
    var id: Int64!

    // Reference to the containing ServerObjectModel
    static let fileGroupUUIDField = Field("fileGroupUUID", \M.fileGroupUUID)
    var fileGroupUUID: UUID

    static let fileUUIDField = Field("fileUUID", \M.fileUUID)
    var fileUUID: UUID
    
    static let fileLabelField = Field("fileLabel", \M.fileLabel)
    var fileLabel: String
    
    // If this is true, then the url field should not be used (it should be nil). The file was reported as `gone` on the server. If it is false, then the url may be nil if it hasn't yet been populated into this record.
    static let goneField = Field("gone", \M.gone)
    var gone: Bool
    
    static let urlField = Field("url", \M.url)
    var url: URL?

    // Fires when the unreadCount of a ServerFileModel changes. The `userInfo` of the notification received contains one key/value pair:
    //      fileUUIDField.fieldName : file UUID
    // Use the method `getFileModel` below to obtain the updated ServerFileModel given this notification.
    static let unreadCountUpdate = NSNotification.Name("ServerFileModel.unreadCount.update")
    
    // The following two fields are non-nil only for files containing comments.
    static let unreadCountField = Field("unreadCount", \M.unreadCount)
    var unreadCount: Int?

    // The number of comments in the comment file the current (device) user has read. In practice, when changed, this always gets set to the current number of comments in the comment file-- i.e., to indicate that the user has read all current comments in the file.
    static let readCountField = Field("readCount", \M.readCount)
    var readCount: Int?
    
    static let badgeUpdate = NSNotification.Name("ServerFileModel.badge.update")
    
    // Only used for Media Item Attribute files. i.e., file label `mediaItemAttributes`. This is not obtained from the server-- it's for local use on the client only. This reflects the badge for the currently signed in user.
    static let badgeField = Field("badge", \M.badge)
    var badge: MediaItemBadge?
    
    enum DownloadStatus: String, Codable {
        case notDownloaded
        case downloading
        case downloaded
    }
    
    // Fires when the download status of a ServerFileModel changes. The `userInfo` of the notification received contains one key/value pair:
    //      fileUUIDField.fieldName : file UUID
    // Use the method `getFileModel` below to obtain the updated ServerFileModel given this notification.
    static let downloadStatusUpdate = NSNotification.Name("ServerFileModel.downloadStatus.update")
    
    // For files created locally and thus not in need of downloading this will be `.downloaded`. (For files that are `gone`, this will always be `.notDownloaded`).
    static let downloadStatusField = Field("downloadStatus", \M.downloadStatus)
    var downloadStatus: DownloadStatus = .notDownloaded
    
    // New as of 5/8/21; Migration needed.
    static let appMetaDataField = Field("appMetaData", \M.appMetaData)
    var appMetaData: String?
    
    init(db: Connection,
        id: Int64! = nil,
        fileGroupUUID: UUID,
        fileUUID: UUID,
        fileLabel: String,
        downloadStatus: DownloadStatus,
        gone: Bool = false,
        url: URL? = nil,
        unreadCount: Int? = nil,
        readCount: Int? = nil,
        appMetaData: String? = nil,
        badge: MediaItemBadge? = nil) throws {
        
        self.db = db
        self.id = id
        self.fileGroupUUID = fileGroupUUID
        self.fileUUID = fileUUID
        self.fileLabel = fileLabel
        self.gone = gone
        self.url = url
        self.unreadCount = unreadCount
        self.readCount = readCount
        self.downloadStatus = downloadStatus
        self.appMetaData = appMetaData
        self.badge = badge
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(fileGroupUUIDField.description)
            t.column(fileUUIDField.description, unique: true)
            t.column(fileLabelField.description)
            t.column(goneField.description)
            t.column(urlField.description)
            t.column(unreadCountField.description)
            t.column(readCountField.description)
            t.column(downloadStatusField.description)
            
            // Added in migration
            // t.column(appMetaDataField.description)
            
            // Added in migration, 6/15/21
            // t.column(badgeField.description)
        }
    }
    
    static func migration_2021_5_8(db: Connection) throws {
        try addColumn(db: db, column: appMetaDataField.description)
    }

    static func migration_2021_6_15(db: Connection) throws {
        try addColumn(db: db, column: badgeField.description)
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> ServerFileModel {
        return try ServerFileModel(db: db,
            id: row[Self.idField.description],
            fileGroupUUID: row[Self.fileGroupUUIDField.description],
            fileUUID: row[Self.fileUUIDField.description],
            fileLabel: row[Self.fileLabelField.description],
            downloadStatus: row[Self.downloadStatusField.description],
            gone: row[Self.goneField.description],
            url: row[Self.urlField.description],
            unreadCount: row[Self.unreadCountField.description],
            readCount: row[Self.readCountField.description],
            appMetaData: row[Self.appMetaDataField.description],
            badge: row[Self.badgeField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.fileGroupUUIDField.description <- fileGroupUUID,
            Self.fileUUIDField.description <- fileUUID,
            Self.fileLabelField.description <- fileLabel,
            Self.goneField.description <- gone,
            Self.urlField.description <- url,
            Self.unreadCountField.description <- unreadCount,
            Self.readCountField.description <- readCount,
            Self.downloadStatusField.description <- downloadStatus,
            Self.appMetaDataField.description <- appMetaData,
            Self.badgeField.description <- badge
        )
    }
}

extension ServerFileModel {
    enum ServerFileModelError: Error {
        case noFileUUID
        case noFileGroupUUID
        case noFileLabel
        case noFileForFileLabel
        case noObject
    }
    
    // Upsert files based on index obtained from the server.
    static func upsert(db: Connection, file: DownloadFile, object: IndexObject) throws {
        if let model = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileUUIDField.description == file.uuid) {
            // This handles both the case of a download deletion (another client has deleted an object/file(s)) and the case of a local deletion. In the local deletion-- the deletion request gets uploaded, and later an index request will occur. This later index request is now driving this upsert.
            if object.deleted, let fileURL = model.url {
                try FileManager.default.removeItem(at: fileURL)
                try model.update(setters: ServerFileModel.urlField.description <- nil)
                logger.info("Removed file: \(fileURL)")
            }
        }
        else {
            // A new file we're just learning about from the server, via an index, will have status `.notDownloaded`
            let model = try ServerFileModel(db: db, fileGroupUUID: object.fileGroupUUID, fileUUID: file.uuid, fileLabel: file.fileLabel, downloadStatus: .notDownloaded)
            try model.insert()
        }
    }
    
    // Same functionality as `fileModels()` in `ServerObjectModel`.
    // This is the same as getting all `ServerFileModel`'s for a `ServerObjectModel`.
    static func getFilesFor(fileGroupUUID: UUID) throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
    }
    
    static func getFileFor(fileLabel: String, withFileGroupUUID fileGroupUUID: UUID) throws -> ServerFileModel {
    
        let fileModels = try getFilesFor(fileGroupUUID: fileGroupUUID)
        let fileModelsWithLabel = fileModels.filter {$0.fileLabel == fileLabel}
        
        guard fileModelsWithLabel.count == 1 else {
            throw ServerFileModelError.noFileForFileLabel
        }
        
        return fileModelsWithLabel[0]
    }
    
    // The file with the file label may not be in the object; in that case, nil is returned. If it is in the object, that file must be in the local database.
    static func getFileFor(fileLabel: String, from object:DownloadedObject) throws -> ServerFileModel? {
    
        let filter = object.downloads.filter { $0.fileLabel == fileLabel }
        switch filter.count {
        case 0:
            return nil
        case 1:
            break
        default:
            throw ServerFileModelError.noObject
        }

        return try getFileFor(fileLabel: fileLabel, withFileGroupUUID: object.fileGroupUUID)
    }
        
    func removeFile() throws {
        if let existingFileURL = url {
            try FileManager.default.removeItem(at: existingFileURL)
        }
    }

    // Doesn't send if app is in the background. Make sure receiving uses of this only drive the UI, or can be reconsituted when the app comes back into the foreground.
    func postDownloadStatusUpdateNotification() {
        guard AppState.session.current == .foreground else {
            return
        }

        NotificationCenter.default.post(name: Self.downloadStatusUpdate, object: nil, userInfo: [ServerFileModel.fileUUIDField.fieldName : fileUUID])
    }
    
    // `sharingGroupUUID` is the sharing group for the object in which this file is contained.
    // Doesn't send if app is in the background. Make sure receiving uses of this only drive the UI, or can be reconsituted when the app comes back into the foreground.
    func postUnreadCountUpdateNotification(sharingGroupUUID: UUID) {
        guard AppState.session.current == .foreground else {
            return
        }
        
        NotificationCenter.default.post(name: Self.unreadCountUpdate, object: nil, userInfo: [
            ServerFileModel.fileUUIDField.fieldName : fileUUID,
            ServerObjectModel.sharingGroupUUIDField.fieldName: sharingGroupUUID
        ])
    }
    
    func postBadgeUpdateNotification() {
        guard AppState.session.current == .foreground else {
            return
        }
        
        NotificationCenter.default.post(name: Self.badgeUpdate, object: nil, userInfo: [
            ServerFileModel.fileUUIDField.fieldName : fileUUID
        ])
    }
    
    static func getUUIDs(from notification: Notification) -> (fileUUID: UUID, sharingGroupUUID: UUID?)? {
        guard let fileValue = notification.userInfo?[ServerFileModel.fileUUIDField.fieldName],
            let fileUUID = fileValue as? UUID else {
            return nil
        }

        let sharingValue = notification.userInfo?[ServerObjectModel.sharingGroupUUIDField.fieldName]
        let sharingGroupUUID = sharingValue as? UUID
        
        return (fileUUID, sharingGroupUUID)
    }
    
    // Use this when receiving a `downloadStatusUpdate` notification.
    // If the fileUUID of the received notification doesn't match that given in the expectingFileUUID, nil is returned.
    static func getFileModel(db: Connection, from notification: Notification, expectingFileUUID: UUID) throws -> ServerFileModel? {
        guard let fileUUID = notification.userInfo?[fileUUIDField.fieldName] as? UUID else {
            throw ServerFileModelError.noFileUUID
        }
        
        guard expectingFileUUID == fileUUID else {
            return nil
        }
        
        guard let fileModel = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileUUIDField.description == fileUUID) else {
            throw ServerFileModelError.noObject
        }
        
        return fileModel
    }
}

extension DownloadedFile {
    // Upsert based on a downloaded file
    // If itemType `DownloadFile.Contents` gives a URL, this moves the file to a permanent Neebla directory and saves it into the relevant `ServerFileModel`.
    func upsert(db: Connection, fileGroupUUID: UUID, itemType: ItemType.Type) throws {
        var contentsURL: URL?
        var gone = false

        let downloadStatus: ServerFileModel.DownloadStatus
        
        switch contents {
        case .download(let url):
            let permanentURL = try itemType.createNewFile(for: fileLabel, mimeType: mimeType)
            _ = try FileManager.default.replaceItemAt(permanentURL, withItemAt: url)
            logger.debug("permanentURL: \(permanentURL)")
            contentsURL = permanentURL
            downloadStatus = .downloaded
        case .gone:
            gone = true
            downloadStatus = .notDownloaded
        }
        
        if var fileModel = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileUUIDField.description == uuid) {
            
            // For an existing file, replaces the content URL. First, get rid of existing file, if any.
            try fileModel.removeFile()
   
            fileModel = try fileModel.update(setters:
                ServerFileModel.goneField.description <- gone,
                ServerFileModel.urlField.description <- contentsURL)
        }
        else {
            let model = try ServerFileModel(db: db, fileGroupUUID: fileGroupUUID, fileUUID: uuid, fileLabel: fileLabel, downloadStatus: downloadStatus, gone: gone, url: contentsURL)
            try model.insert()
        }
    }
}

extension Array where Element == DownloadedFile {
    // Update the downloadStatus of the associated `ServerFileModel`'s
    func update(db: Connection, downloadStatus: ServerFileModel.DownloadStatus) throws {
        for file in self {
            var gone: Bool = false
            switch file.contents {
            case .download:
                break
            case .gone:
                gone = true
            }
            
            guard let fileModel = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileUUIDField.description == file.uuid) else {
                throw DatabaseModelError.notExactlyOneRow
            }
            
            try fileModel.update(setters: ServerFileModel.downloadStatusField.description <- downloadStatus,
                ServerFileModel.goneField.description <- gone,
                ServerFileModel.appMetaDataField.description <- file.appMetaData
            )
            
            fileModel.postDownloadStatusUpdateNotification()
        }
    }
}

extension ServerFileModel {
    func debugOutput() throws {
        logger.notice("url: \(String(describing: url)); fileLabel: \(fileLabel); gone: \(gone); downloadStatus: \(downloadStatus)")
        let downloadsQueued = try Services.session.syncServer.numberQueued(.download)
        logger.notice("downloadsQueued: \(downloadsQueued)")
        try Services.session.syncServer.debug(fileUUID: fileUUID)
        try Services.session.syncServer.debug(fileGroupUUID: fileGroupUUID)
        let needsDownload = try Services.session.syncServer.objectNeedsDownload(fileGroupUUID: fileGroupUUID, includeGone: true)
        logger.notice("objectNeedsDownload: \(String(describing: needsDownload))")
    }
}
