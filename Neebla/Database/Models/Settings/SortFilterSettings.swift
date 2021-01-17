//
//  SortFilterSettings.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/17/21.
//

import SQLite
import Foundation
import iOSShared

// Supporting the Sort / Filter menu on the Album Items screen

class SortFilterSettings: DatabaseModel, SingletonModel {
    let db: Connection
    var id: Int64!
    
    enum SortBy: String, Codable {
        case creationDate
    }
    
    static let sortByField = Field("sortBy", \M.sortBy)
    var sortBy: SortBy
    
    static let sortByOrderAscendingField = Field("sortByOrderAscending", \M.sortByOrderAscending)
    // Ascending if true; descending if false.
    var sortByOrderAscending: Bool
    
    enum DiscussionFilterBy: String, Codable, CaseIterable {
        case none // no filtering; show all
        case onlyUnread
    }
    
    static let discussionFilterByField = Field("discussionFilterBy", \M.discussionFilterBy)
    var discussionFilterBy: DiscussionFilterBy
    
    init(db: Connection,
        id: Int64! = nil,
        sortBy: SortBy = .creationDate,
        sortByOrderAscending: Bool = true,
        discussionFilterBy: DiscussionFilterBy = .none) throws {

        self.id = id
        self.db = db
        self.sortBy = sortBy
        self.sortByOrderAscending = sortByOrderAscending
        self.discussionFilterBy = discussionFilterBy
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(Self.sortByField.description)
            t.column(Self.sortByOrderAscendingField.description)
            t.column(Self.discussionFilterByField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> SortFilterSettings {
        return try SortFilterSettings(db: db,
            id: row[Self.idField.description],
            sortBy: row[Self.sortByField.description],
            sortByOrderAscending: row[Self.sortByOrderAscendingField.description],
            discussionFilterBy: row[Self.discussionFilterByField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.sortByField.description <- sortBy,
            Self.sortByOrderAscendingField.description <- sortByOrderAscending,
            Self.discussionFilterByField.description <- discussionFilterBy
        )
    }
    
    // MARK: SingletonModel
    
    static func createSingletonRow(db: Connection) throws -> SortFilterSettings {
        return try SortFilterSettings(db: db)
    }
}

extension SortFilterSettings.SortBy: Value {
    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    
    public static func fromDatatypeValue(_ blobValue: Blob) -> SortFilterSettings.SortBy {
        let decoder = JSONDecoder()
        return try! decoder.decode(SortFilterSettings.SortBy.self, from: Data.fromDatatypeValue(blobValue))
    }
    
    public var datatypeValue: Blob {
        let encoder = JSONEncoder()
        return try! encoder.encode(self).datatypeValue
    }
}

extension SortFilterSettings.DiscussionFilterBy: Value {
    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    
    public static func fromDatatypeValue(_ blobValue: Blob) -> SortFilterSettings.DiscussionFilterBy {
        let decoder = JSONDecoder()
        return try! decoder.decode(SortFilterSettings.DiscussionFilterBy.self, from: Data.fromDatatypeValue(blobValue))
    }
    
    public var datatypeValue: Blob {
        let encoder = JSONEncoder()
        return try! encoder.encode(self).datatypeValue
    }
}
