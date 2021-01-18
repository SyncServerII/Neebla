
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
    
    static let deletedField = Field("deleted", \M.deleted)
    var deleted: Bool
    
    // Redundant with the field in the associated comment ServerFileModel-- but seem to need this for searching. Not making this optional because I can't seem to search by optional fields with SQLite.
    static let unreadCountField = Field("unreadCount", \M.unreadCount)
    var unreadCount: Int
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        fileGroupUUID: UUID,
        objectType: String,
        creationDate: Date,
        updateCreationDate: Bool,
        deleted: Bool = false,
        unreadCount:Int = 0) throws {

        self.db = db
        self.id = id
        self.fileGroupUUID = fileGroupUUID
        self.sharingGroupUUID = sharingGroupUUID
        self.objectType = objectType
        self.creationDate = creationDate
        self.updateCreationDate = updateCreationDate
        self.deleted = deleted
        self.unreadCount = unreadCount
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
            lhs.unreadCount == rhs.unreadCount
    }
    
    // MARK: BasicEquatable

    func basicallyEqual(_ other: ServerObjectModel) -> Bool {
        return fileGroupUUID == other.fileGroupUUID
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
            deleted: row[Self.deletedField.description],
            unreadCount: row[Self.unreadCountField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.fileGroupUUIDField.description <- fileGroupUUID,
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.objectTypeField.description <- objectType,
            Self.creationDateField.description <- creationDate,
            Self.updateCreationDateField.description <- updateCreationDate,
            Self.deletedField.description <- deleted,
            Self.unreadCountField.description <- unreadCount
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
    
    static func upsert(db: Connection, indexObject: IndexObject) throws {
        if let model = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == indexObject.fileGroupUUID) {
            
            if model.updateCreationDate {
                try model.update(setters:
                    ServerObjectModel.creationDateField.description <- indexObject.creationDate,
                    ServerObjectModel.updateCreationDateField.description <- false)
            }
            
            try model.update(setters:
                ServerObjectModel.deletedField.description <- indexObject.deleted)
        }
        else {
            let model = try ServerObjectModel(db: db, sharingGroupUUID: indexObject.sharingGroupUUID, fileGroupUUID: indexObject.fileGroupUUID, objectType: indexObject.objectType, creationDate: indexObject.creationDate, updateCreationDate: false, deleted: indexObject.deleted)
            try model.insert()
        }
    }
    
    func getCommentsUnreadCount() throws -> Int? {
        let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: fileGroupUUID)
        logger.debug("fileModel.unreadCount: \(String(describing: fileModel.unreadCount))")
        return fileModel.unreadCount
    }
    
    // Same functionality as `getFilesFor(fileGroupUUID: UUID)` in `ServerFileModel`.
    func fileModels() throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
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
