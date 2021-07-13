
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
    
    // Set as the max update date of all files in the object when object updates downloaded, and when an index/sync is done.
    static let updateDateField = Field("updateDate", \M.updateDate)
    var updateDate: Date?
    
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
        keywords: String? = nil) throws {

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
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ServerObjectModel, rhs: ServerObjectModel) -> Bool {
        return lhs.id == rhs.id &&
            lhs.fileGroupUUID == rhs.fileGroupUUID &&
            lhs.sharingGroupUUID == rhs.sharingGroupUUID &&
            lhs.objectType == rhs.objectType &&
            lhs.creationDate == rhs.creationDate &&
            lhs.updateCreationDate == rhs.updateCreationDate &&
            lhs.deleted == rhs.deleted &&
            lhs.unreadCount == rhs.unreadCount &&
            lhs.updateDate == rhs.updateDate &&
            lhs.keywords == rhs.keywords
    }
    
    // MARK: BasicEquatable

    func basicallyEqual(_ other: ServerObjectModel) -> Bool {
        return fileGroupUUID == other.fileGroupUUID
    }
    
    // MARK: Migrations
    
    static func migration_2021_7_1(db: Connection) throws {
        try addColumn(db: db, column: keywordsField.description)
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
            keywords: row[Self.keywordsField.description]
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
            Self.keywordsField.description <- keywords
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
            
            if let updateDate = indexObject.updateDate {
                try model.update(setters:
                    ServerObjectModel.updateDateField.description <- updateDate)
            }
            
            // See https://github.com/SyncServerII/Neebla/issues/23
            if indexObject.sharingGroupUUID != model.sharingGroupUUID {
                try model.update(setters:
                    ServerObjectModel.sharingGroupUUIDField.description <- indexObject.sharingGroupUUID)
            }
        }
        else {
            let model = try ServerObjectModel(db: db, sharingGroupUUID: indexObject.sharingGroupUUID, fileGroupUUID: indexObject.fileGroupUUID, objectType: indexObject.objectType, creationDate: indexObject.creationDate, updateCreationDate: false, deleted: indexObject.deleted)
            try model.insert()
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
            
            if let updateDate = (downloads.compactMap {$0.updateDate}).max() {
                try model.update(setters:
                    ServerObjectModel.updateDateField.description <- updateDate)
            }
        }
        else {
            let objectModel = try ServerObjectModel(db: db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: itemType.objectType, creationDate: creationDate, updateCreationDate: false)
            try objectModel.insert()
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
