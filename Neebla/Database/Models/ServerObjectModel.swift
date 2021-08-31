
import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics

// Each "object" represents an image, a URL, or other top-level entity in an album.

class ServerObjectModel: DatabaseModel, ObservableObject, BasicEquatable, Equatable, Hashable {
    let db: Connection
    var id: Int64!

    // The sharing group in which this object is contained.
    static let sharingGroupUUIDField = Field("sharingGroupUUID", \M.sharingGroupUUID)
    @Published var sharingGroupUUID: UUID
    
    // The file group of the object.
    static let fileGroupUUIDField = Field("fileGroupUUID", \M.fileGroupUUID)
    var fileGroupUUID: UUID
    
    // SyncServer objectType
    static let objectTypeField = Field("objectType", \M.objectType)
    var objectType: String
    
    // When an object is uploaded/created on this client, the `creationDate` is just approximately at the start. The server sets the final `creationDate`. A locally created object has `updateCreationDate` == true, and `updateCreationDate` is reset once the date is updated from the server.
    static let creationDateField = Field("creationDate", \M.creationDate)
    var creationDate: Date
    
    // See `creationDate`.
    static let updateCreationDateField = Field("updateCreationDate", \M.updateCreationDate)
    var updateCreationDate: Bool
    
    // Before 8/27/21, this was set as the max update date of all files in the object when object updates downloaded, and when an index/sync is done.
    // After this, I'm using it more specifically. It's going to reflect only the update date of comment files in the object. This is so I can use this for a user-observable modification date in the album items screen. i.e., not all file changes are user observable.
    static let updateDateField = Field("updateDate", \M.updateDate)
    var updateDate: Date?
    static let updateDateChanged = NSNotification.Name("ServerObjectModel.updateDate.changed")
    
    static let deletedField = Field("deleted", \M.deleted)
    var deleted: Bool
    
    // Redundant with the field in the associated comment ServerFileModel-- but seem to need this for searching. Not making this optional because I can't seem to search by optional fields with SQLite.
    static let unreadCountField = Field("unreadCount", \M.unreadCount)
    var unreadCount: Int

    // keywords stored in CSV format, to enable searching.
    static let keywordsField = Field("keywords", \M.keywords)
    var keywords: String?

    // Fires when the keywords of a ServerObjectModel changes.
    static let keywordsUpdate = NSNotification.Name("ServerObjectModel.keywords.update")
    
    // Migration, 8/26/21
    // Has the object ever been viewed? This can only ever transition from false to true.
    static let newField = Field("new", \M.new)
    var new: Bool
    static let newUpdate = NSNotification.Name("ServerObjectModel.new.update")
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        fileGroupUUID: UUID,
        objectType: String,
        creationDate: Date,
        updateCreationDate: Bool,
        updateDate: Date? = nil,
        deleted: Bool = false,
        unreadCount:Int = 0,
        keywords: String? = nil,
        new: Bool = false) throws {

        self.db = db
        self.id = id
        self.fileGroupUUID = fileGroupUUID
        self.sharingGroupUUID = sharingGroupUUID
        self.objectType = objectType
        self.creationDate = creationDate
        self.updateDate = updateDate
        self.updateCreationDate = updateCreationDate
        self.deleted = deleted
        self.unreadCount = unreadCount
        self.keywords = keywords
        self.new = new
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // This is used just in the AlbumItemsViewModel and is intended as "approximately equal". Or "identity equal".
    static func == (lhs: ServerObjectModel, rhs: ServerObjectModel) -> Bool {
        return lhs.id == rhs.id &&
            lhs.fileGroupUUID == rhs.fileGroupUUID &&
            lhs.sharingGroupUUID == rhs.sharingGroupUUID &&
            lhs.objectType == rhs.objectType
    }
    
    // MARK: BasicEquatable

    func basicallyEqual(_ other: ServerObjectModel) -> Bool {
        return fileGroupUUID == other.fileGroupUUID
    }
    
    // MARK: Meta data migrations
    
    static func migration_2021_7_1(db: Connection) throws {
        try addColumn(db: db, column: keywordsField.description)
    }
    
    static func migration_2021_8_26(db: Connection) throws {
        // Defaulting `new` to false so that people don't have existing items showing up as `new`.
        try addColumn(db: db, column: newField.description, defaultValue: false)
    }

    // MARK: Content migrations

    // Bring all objects up to date in terms of their `updateDateField`.
    static func migration_2021_8_27(db: Connection, syncServer: SyncServer) throws {
        let objects = try ServerObjectModel.fetch(db: db)
        for object in objects {
            do {
                guard let commentFileModel = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileGroupUUIDField.description == object.fileGroupUUID &&
                    ServerFileModel.fileLabelField.description == FileLabels.comments) else {
                    continue
                }
                
                guard let fileAttributes = try syncServer.fileAttributes(forFileUUID: commentFileModel.fileUUID) else {
                    logger.error("migration_2021_8_27: Could not get attributes for fileUUID: \(commentFileModel.fileUUID)")
                    continue
                }
                
                try object.update(setters: ServerObjectModel.updateDateField.description <- fileAttributes.updateDate)
            } catch let error {
                logger.error("migration_2021_8_27: \(error)")
            }
        }
    }

    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(fileGroupUUIDField.description, unique: true)
            t.column(sharingGroupUUIDField.description)
            t.column(objectTypeField.description)
            t.column(creationDateField.description)
            t.column(updateCreationDateField.description)
            t.column(deletedField.description)
            t.column(unreadCountField.description)
            t.column(updateDateField.description)
            
            // Migration
            // t.column(keywordsField.description)
            
            // Migration
            // t.column(newField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> ServerObjectModel {
        return try ServerObjectModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            fileGroupUUID: row[Self.fileGroupUUIDField.description],
            objectType: row[Self.objectTypeField.description],
            creationDate: row[Self.creationDateField.description],
            updateCreationDate: row[Self.updateCreationDateField.description],
            updateDate: row[Self.updateDateField.description],
            deleted: row[Self.deletedField.description],
            unreadCount: row[Self.unreadCountField.description],
            keywords: row[Self.keywordsField.description],
            new: row[Self.newField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.fileGroupUUIDField.description <- fileGroupUUID,
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.objectTypeField.description <- objectType,
            Self.creationDateField.description <- creationDate,
            Self.updateCreationDateField.description <- updateCreationDate,
            Self.updateDateField.description <- updateDate,
            Self.deletedField.description <- deleted,
            Self.unreadCountField.description <- unreadCount,
            Self.keywordsField.description <- keywords,
            Self.newField.description <- new
        )
    }
}

extension ServerObjectModel {
    enum ServerObjectModelError: Error {
        case noSharingGroupUUID
        case noFileGroupUUID
        case noObjectType
        case noCreationDate
    }

    enum UpsertResult {
        case firstTimeDeletion
    }
    
    // Returns `firstTimeDeletion` iff the `IndexObject` indicated that the object is deleted, and this call marks the `ServerObjectModel` as deleted for the first time. i.e., prior to this call the `ServerObjectModel` was not marked as deleted.
    static func upsert(db: Connection, indexObject: IndexObject) throws -> UpsertResult? {
        var result: UpsertResult?
        
        if let model = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == indexObject.fileGroupUUID) {
            
            if model.updateCreationDate {
                try model.update(setters:
                    ServerObjectModel.creationDateField.description <- indexObject.creationDate,
                    ServerObjectModel.updateCreationDateField.description <- false)
            }
            
            if indexObject.deleted && !model.deleted {
                result = .firstTimeDeletion
                
                try model.update(setters:
                    ServerObjectModel.deletedField.description <- indexObject.deleted)
            }
            
            logger.debug("model.deleted: \(model.deleted)")
            
            // See comment in `updateDateField` in ServerObjectModel dated 8/27/21
            // if let updateDate = indexObject.updateDate {
            //    try model.update(setters:
            //        ServerObjectModel.updateDateField.description <- updateDate)
            // }
            
            // See https://github.com/SyncServerII/Neebla/issues/23
            if indexObject.sharingGroupUUID != model.sharingGroupUUID {
                try model.update(setters:
                    ServerObjectModel.sharingGroupUUIDField.description <- indexObject.sharingGroupUUID)
            }
        }
        else {
            let model = try ServerObjectModel(db: db, sharingGroupUUID: indexObject.sharingGroupUUID, fileGroupUUID: indexObject.fileGroupUUID, objectType: indexObject.objectType, creationDate: indexObject.creationDate, updateCreationDate: false, deleted: indexObject.deleted, new: true)
            try model.insert()
            model.postNewUpdateNotification()
        }
        
        return result
    }
    
    func getCommentsUnreadCount() throws -> Int? {
        let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: fileGroupUUID)
        return fileModel.unreadCount
    }
    
    // Same functionality as `getFilesFor(fileGroupUUID: UUID)` in `ServerFileModel`.
    func fileModels() throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
    }
    
    // Returns a count of the number of files of the object that have a nil `url` property.
    func filesNotDownloaded() throws -> Int {
        let files = try fileModels()
        let notDownloaded = files.filter { $0.url == nil }
        return notDownloaded.count
    }
    
    func allFilesDownloaded() throws -> Bool {
        return try filesNotDownloaded() == 0
    }
    
    static func albumFor(fileGroupUUID: UUID, db: Connection) throws -> AlbumModel {
        guard let objectModel = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) else {
            throw DatabaseModelError.notExactlyOneRow
        }
        
        guard let albumModel = try AlbumModel.fetchSingleRow(db: db, where: AlbumModel.sharingGroupUUIDField.description == objectModel.sharingGroupUUID) else {
            throw DatabaseModelError.notExactlyOneRow
        }
        
        return albumModel
    }
}

extension DownloadedObject {
    // Upsert based on a downloaded object
    func upsert(db: Connection, itemType: ItemType.Type) throws {
        if let model = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) {

            if model.updateCreationDate {
                try model.update(setters:
                    ServerObjectModel.creationDateField.description <- creationDate,
                    ServerObjectModel.updateCreationDateField.description <- false)
            }
            
            // Only updating the object model updateDateField based on comment files. See comment in ServerObjectModel on 8/27/21.
            let commentDownload = downloads.filter {$0.fileLabel == FileLabels.comments}
            if commentDownload.count == 1 {
                let commentUpdateDate = commentDownload[0].updateDate
                try model.update(setters:
                    ServerObjectModel.updateDateField.description <- commentUpdateDate)
                model.postUpdateDateChangedNotification()
            }
        }
        else {
            let objectModel = try ServerObjectModel(db: db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: itemType.objectType, creationDate: creationDate, updateCreationDate: false, new: true)
            try objectModel.insert()
            objectModel.postNewUpdateNotification()
        }
        
        // Independent of whether this was a new object or an existing object, do upsert for the files.
        for file in downloads {
            try file.upsert(db: db, fileGroupUUID: fileGroupUUID, itemType: itemType)
        }
    }
}

extension ServerObjectModel {
    func debugOutput() throws {
        let files = try fileModels()
        logger.notice("Object: objectType: \(objectType)")
        
        for file in files {
            try file.debugOutput()
        }
    }
    
    func postKeywordsUpdateNotification() {
        guard AppState.session.current == .foreground else {
            return
        }
        
        var userInfo:[String: Any] = [
            ServerObjectModel.fileGroupUUIDField.fieldName : fileGroupUUID
        ]
        
        userInfo[ServerObjectModel.keywordsField.fieldName] = keywords
        
        logger.debug("Post: Keywords: \(String(describing: keywords))")
        
        NotificationCenter.default.post(name: Self.keywordsUpdate, object: nil, userInfo: userInfo)
    }
    
    static func getKeywordInfo(from notification: Notification) -> (fileGroupUUID: UUID, keywords: String?)? {
        guard let fileGroupUUID = notification.userInfo?[ServerObjectModel.fileGroupUUIDField.fieldName] as? UUID else {
            return nil
        }
        
        let keywords = notification.userInfo?[ServerObjectModel.keywordsField.fieldName] as? String
        
        return (fileGroupUUID, keywords)
    }

    // This is called exactly when the `new` field of the ServerObjectModel changes. (It does not reflect specifics about the download state of the object's models, such as the download state of the main media item file of the object).
    func postNewUpdateNotification() {
        guard AppState.session.current == .foreground else {
            return
        }
        
        NotificationCenter.default.post(name: Self.newUpdate, object: nil, userInfo: [
            ServerObjectModel.fileGroupUUIDField.fieldName : fileGroupUUID
        ])
    }
    
    static func getFileGroupUUID(from notification: Notification) -> UUID? {
        guard let value = notification.userInfo?[ServerObjectModel.fileGroupUUIDField.fieldName],
            let fileGroupUUID = value as? UUID else {
            return nil
        }
        
        return fileGroupUUID
    }
    
    func postUpdateDateChangedNotification() {
        guard AppState.session.current == .foreground else {
            return
        }
        
        NotificationCenter.default.post(name: Self.updateDateChanged, object: nil, userInfo: [
            ServerObjectModel.fileGroupUUIDField.fieldName : fileGroupUUID
        ])
    }
    
    // See https://github.com/SyncServerII/Neebla/issues/23
    static func updateSharingGroups(ofFileGroups fileGroups: [UUID], destinationSharinGroup:UUID, db: Connection) throws {
        
        for fileGroup in fileGroups {
            guard let object = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroup) else {
                throw DatabaseModelError.notExactlyOneRow
            }
            
            try object.update(setters: ServerObjectModel.sharingGroupUUIDField.description <- destinationSharinGroup)
        }
    }
}
