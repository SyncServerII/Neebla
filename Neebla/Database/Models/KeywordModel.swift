//
//  KeywordModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/27/21.
//

import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics
import ChangeResolvers

class KeywordModel: DatabaseModel {
    let db: Connection
    var id: Int64!
    
    static let sharingGroupUUIDField = Field("sharingGroupUUID", \M.sharingGroupUUID)
    var sharingGroupUUID: UUID

    static let keywordField = Field("keyword", \M.keyword)
    var keyword: String
    
    static let deletedField = Field("deleted", \M.deleted)
    var deleted: Bool
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        keyword: String,
        deleted: Bool = false) throws {

        self.db = db
        self.id = id
        self.sharingGroupUUID = sharingGroupUUID
        self.keyword = keyword
        self.deleted = deleted
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(sharingGroupUUIDField.description)
            t.column(keywordField.description)
            t.unique(sharingGroupUUIDField.description, keywordField.description)
            
            // Migration
            // t.column(deletedField.description)
        }
    }
    
    static func migration_2021_7_1(db: Connection) throws {
        try addColumn(db: db, column: deletedField.description, defaultValue: false)
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> KeywordModel {
        return try KeywordModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            keyword: row[Self.keywordField.description],
            deleted: row[Self.deletedField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.keywordField.description <- keyword,
            Self.deletedField.description <- deleted
        )
    }
}

extension KeywordModel {
    static func keywords(forSharingGroupUUID sharingGroupUUID: UUID, deleted: Bool? = nil, db: Connection) throws -> Set<String> {
        let keywordModels: [KeywordModel]
        if let deleted = deleted {
            keywordModels = try KeywordModel.fetch(db: db, where: KeywordModel.sharingGroupUUIDField.description == sharingGroupUUID &&
                KeywordModel.deletedField.description == deleted)
        }
        else {
            keywordModels = try KeywordModel.fetch(db: db, where: KeywordModel.sharingGroupUUIDField.description == sharingGroupUUID)
        }
        
        return Set<String>(keywordModels.map { $0.keyword })
    }
}

extension MediaItemAttributes {
    func addKeywordsToKeywordModelsIfNeeded(sharingGroupUUID: UUID, db: Connection) throws {
        let currentAlbumKeywords = try KeywordModel.keywords(forSharingGroupUUID: sharingGroupUUID, db: db)
        
        // I'm setting `onlyThoseUsed` to true so that a keyword can be removed, and then not show up in the general album keywords again later.
        let miaKeywords = getKeywords(onlyThoseUsed: true)
        
        // Get the keywords that we haven't yet stored locally.
        let difference = miaKeywords.subtracting(currentAlbumKeywords)
        for keyword in difference {
            let newKeywordModel = try KeywordModel(db: db, sharingGroupUUID: sharingGroupUUID, keyword: keyword)
            try newKeywordModel.insert()
        }
        
        // Check for keywords deleted locally. This covers the case of a keyword removed earlier and then re-added.
        let currentAlbumKeywordsDeleted = try KeywordModel.keywords(forSharingGroupUUID: sharingGroupUUID, deleted: true, db: db)
        let intersection = miaKeywords.intersection(currentAlbumKeywordsDeleted)
        
        for keyword in intersection {
            guard let keywordModel = try KeywordModel.fetchSingleRow(db: db, where: KeywordModel.keywordField.description == keyword) else {
                throw DatabaseModelError.notExactlyOneRow(message: "addKeywordsToKeywordModelsIfNeeded")
            }
            
            try keywordModel.update(setters: KeywordModel.deletedField.description <- false)
        }
    }
}
