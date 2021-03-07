
import SQLite
import Foundation
import iOSShared
import CoreGraphics

// Support for the Settings screen.

class SettingsModel: DatabaseModel, SingletonModel {
    let db: Connection
    var id: Int64!
    
    enum SettingsModelError: Error {
        case badUserNameUpdate
    }

    static let defaultJPEGQuality: CGFloat = 0.7

    static let jpegQualityField = Field("jpegQuality", \M.jpegQuality)
    var jpegQuality: CGFloat

    static let minimumUserNameLength = 1
    static let userNameField = Field("userName", \M.userName)
    var userName: String?
    
    init(db: Connection,
        id: Int64! = nil,
        jpegQuality: CGFloat,
        userName: String? = nil) throws {

        self.db = db
        self.id = id
        self.jpegQuality = jpegQuality
        self.userName = userName
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(Self.jpegQualityField.description)
            t.column(Self.userNameField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> SettingsModel {
        return try SettingsModel(db: db,
            id: row[Self.idField.description],
            jpegQuality: row[Self.jpegQualityField.description],
            userName: row[Self.userNameField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.jpegQualityField.description <- jpegQuality,
            Self.userNameField.description <- userName
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
    
    static func userName(db: Connection) throws -> String? {
        let settings = try SettingsModel.getSingleton(db: Services.session.db)
        return settings.userName
    }
    
    // If new user name is valid, returned the trimmed new user name.
    static func checkForValidUserNameUpdate(oldUserName: String?, newUserName: String?) -> String? {
        guard let userName = newUserName?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        
        guard userName.count >= minimumUserNameLength else {
            return nil
        }
        
        guard userName != oldUserName else {
            return nil
        }
        
        return userName
    }
    
    static func update(userName: String?, db: Connection) throws {
        let settings = try SettingsModel.getSingleton(db: Services.session.db)
        guard let userName = checkForValidUserNameUpdate(oldUserName: settings.userName, newUserName: userName) else {
            throw SettingsModelError.badUserNameUpdate
        }
        
        try settings.update(setters: SettingsModel.userNameField.description <- userName)
    }
    
    static func setupUserName(userName: String?) throws {
        let currentUserName = try SettingsModel.userName(db: Services.session.db)
        logger.debug("setupUserName: update: \(String(describing: userName)); currentUserName: \(String(describing: currentUserName))")
        try SettingsModel.update(userName: userName, db: Services.session.db)
    }
}
