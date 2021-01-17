
import SQLite
import Foundation
import iOSShared
import CoreGraphics

// Support for the Settings screen.

class SettingsModel: DatabaseModel, SingletonModel {
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
    
    // MARK: SingletonModel
    
    static func createSingletonRow(db: Connection) throws -> SettingsModel {
        return try SettingsModel(db: db, jpegQuality: defaultJPEGQuality)
    }
}

extension SettingsModel {    
    static func jpegQuality(db: Connection) throws -> CGFloat {
        let settings = try SettingsModel.getSingleton(db: Services.session.db)
        return settings.jpegQuality
    }
}
