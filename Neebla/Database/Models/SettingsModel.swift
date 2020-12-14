
import SQLite
import Foundation
import iOSShared
import CoreGraphics

// This is a singleton. Just one row.

class SettingsModel: DatabaseModel {
    let db: Connection
    var id: Int64!

    static let defaultJPEGQuality: CGFloat = 0.7

    static let jpegQualityField = Field("jpegQuality", \M.jpegQuality)
    var jpegQuality: CGFloat
    
    init(db: Connection,
        id: Int64! = nil,
        jpegQuality: CGFloat) throws {

        self.db = db
        self.id = id
        self.jpegQuality = jpegQuality
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(Self.jpegQualityField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> SettingsModel {
        return try SettingsModel(db: db,
            id: row[Self.idField.description],
            jpegQuality: row[Self.jpegQualityField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.jpegQualityField.description <- jpegQuality
        )
    }
}

extension SettingsModel {
    // Set up the singleton if not present.
    static func initializeSingleton(db: Connection) throws {
        let result = try SettingsModel.fetch(db: db)
        switch result.count {
        case 1:
            return
            
        case 0:
            break
            
        default:
            throw DatabaseModelError.moreThanOneRowInResult
        }
        
        let singleton = try SettingsModel(db: db, jpegQuality: defaultJPEGQuality)
        try singleton.insert()
    }
    
    static func getSingleton(db: Connection) throws -> SettingsModel {
        let singleton = try SettingsModel.fetch(db: db)
        
        guard singleton.count == 1 else {
            throw DatabaseModelError.notExactlyOneRow
        }
        
        return singleton[0]
    }
}
