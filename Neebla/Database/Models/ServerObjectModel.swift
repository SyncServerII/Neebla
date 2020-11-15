
import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics

// Each "object" represents an image, a URL, or other top-level entity in an album.

class ServerObjectModel: DatabaseModel, ObservableObject {
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
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        fileGroupUUID: UUID,
        objectType: String) throws {

        self.db = db
        self.id = id
        self.fileGroupUUID = fileGroupUUID
        self.sharingGroupUUID = sharingGroupUUID
        self.objectType = objectType
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(fileGroupUUIDField.description, unique: true)
            t.column(sharingGroupUUIDField.description)
            t.column(objectTypeField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> ServerObjectModel {
        return try ServerObjectModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            fileGroupUUID: row[Self.fileGroupUUIDField.description],
            objectType: row[Self.objectTypeField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.fileGroupUUIDField.description <- fileGroupUUID,
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.objectTypeField.description <- objectType
        )
    }
}

extension ServerObjectModel {
    enum ServerObjectModelError: Error {
        case noSharingGroupUUID
        case noFileGroupUUID
        case noObjectType
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
        
        if let _ = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) {
            // Nothing yet.
        }
        else {
            let model = try ServerObjectModel(db: db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType)
            try model.insert()
        }
    }
}

extension DownloadedObject {
    func upsert(db: Connection, itemType: ItemType.Type) throws {
        let objectModel: ServerObjectModel
        if let model = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) {
            objectModel = model
        }
        else {
            objectModel = try ServerObjectModel(db: db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: itemType.objectType)
            try objectModel.insert()
        }
        
        for file in downloads {
            try file.upsert(db: db, fileGroupUUID: fileGroupUUID, itemType: itemType)
        }
    }
}