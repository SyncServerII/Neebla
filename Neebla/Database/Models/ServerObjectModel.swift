
import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics

// Each "object" represents an image, a URL, or other top-level entity in an album.

class ServerObjectModel: DatabaseModel, ObservableObject, BasicEquatable {
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
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        fileGroupUUID: UUID,
        objectType: String,
        creationDate: Date,
        updateCreationDate: Bool) throws {

        self.db = db
        self.id = id
        self.fileGroupUUID = fileGroupUUID
        self.sharingGroupUUID = sharingGroupUUID
        self.objectType = objectType
        self.creationDate = creationDate
        self.updateCreationDate = updateCreationDate
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
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> ServerObjectModel {
        return try ServerObjectModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            fileGroupUUID: row[Self.fileGroupUUIDField.description],
            objectType: row[Self.objectTypeField.description],
            creationDate: row[Self.creationDateField.description],
            updateCreationDate: row[Self.updateCreationDateField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.fileGroupUUIDField.description <- fileGroupUUID,
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.objectTypeField.description <- objectType,
            Self.creationDateField.description <- creationDate,
            Self.updateCreationDateField.description <- updateCreationDate
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
    
    static func upsert(db: Connection, fileInfo: FileInfo) throws {
        guard let fileGroupUUID = try UUID.from(fileInfo.fileGroupUUID) else {
            throw ServerObjectModelError.noFileGroupUUID
        }
        
        guard let sharingGroupUUID = try UUID.from(fileInfo.sharingGroupUUID) else {
            throw ServerObjectModelError.noSharingGroupUUID
        }
        
        guard let objectType = fileInfo.objectType else {
            throw ServerObjectModelError.noObjectType
        }
        
        guard let creationDate = fileInfo.creationDate else {
            throw ServerObjectModelError.noCreationDate
        }
        
        if let model = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) {
            
            if model.updateCreationDate {
                try model.update(setters:
                    ServerObjectModel.creationDateField.description <- creationDate,
                    ServerObjectModel.updateCreationDateField.description <- false)
            }
        }
        else {
            let model = try ServerObjectModel(db: db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: creationDate, updateCreationDate: false)
            try model.insert()
        }
    }
}

extension DownloadedObject {
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
