
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
    
    init(db: Connection,
        id: Int64! = nil,
        fileGroupUUID: UUID,
        fileUUID: UUID,
        fileLabel: String,
        gone: Bool = false,
        url: URL? = nil) throws {

        self.db = db
        self.id = id
        self.fileGroupUUID = fileGroupUUID
        self.fileUUID = fileUUID
        self.fileLabel = fileLabel
        self.gone = gone
        self.url = url
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
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> ServerFileModel {
        return try ServerFileModel(db: db,
            id: row[Self.idField.description],
            fileGroupUUID: row[Self.fileGroupUUIDField.description],
            fileUUID: row[Self.fileUUIDField.description],
            fileLabel: row[Self.fileLabelField.description],
            gone: row[Self.goneField.description],
            url: row[Self.urlField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.fileGroupUUIDField.description <- fileGroupUUID,
            Self.fileUUIDField.description <- fileUUID,
            Self.fileLabelField.description <- fileLabel,
            Self.goneField.description <- gone,
            Self.urlField.description <- url
        )
    }
}

extension ServerFileModel {
    enum ServerFileModelError: Error {
        case noFileUUID
        case noFileGroupUUID
        case noFileLabel
    }
    
    static func upsert(db: Connection, fileInfo: FileInfo) throws {
        guard let fileUUID = try UUID.from(fileInfo.fileUUID) else {
            throw ServerFileModelError.noFileUUID
        }
        
        guard let fileGroupUUID = try UUID.from(fileInfo.fileGroupUUID) else {
            throw ServerFileModelError.noFileGroupUUID
        }
        
        guard let fileLabel = fileInfo.fileLabel else {
            throw ServerFileModelError.noFileLabel
        }
        
        if let _ = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileUUIDField.description == fileUUID) {
            // Nothing yet.
        }
        else {
            let model = try ServerFileModel(db: db, fileGroupUUID: fileGroupUUID, fileUUID: fileUUID, fileLabel: fileLabel)
            try model.insert()
        }
    }
}

extension DownloadedFile {
    // If `DownloadFile.Contents` gives a URL, this moves the file to a permanent Neebla directory.
    func upsert(db: Connection, fileGroupUUID: UUID, itemType: ItemType.Type) throws {
        if let _ = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileUUIDField.description == uuid) {
            // Nothing yet.
        }
        else {
            var contentsURL: URL?
            var gone = false
            
            switch contents {
            case .download(let url):
                let permanentURL = try itemType.createNewFile(for: fileLabel)
                _ = try FileManager.default.replaceItemAt(permanentURL, withItemAt: url)
                contentsURL = permanentURL
            case .gone:
                gone = true
            }

            let model = try ServerFileModel(db: db, fileGroupUUID: fileGroupUUID, fileUUID: uuid, fileLabel: fileLabel, gone: gone, url: contentsURL)
            try model.insert()
        }
    }
}
