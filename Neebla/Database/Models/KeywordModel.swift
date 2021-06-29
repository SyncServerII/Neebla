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
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        keyword: String) throws {

        self.db = db
        self.id = id
        self.sharingGroupUUID = sharingGroupUUID
        self.keyword = keyword
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(sharingGroupUUIDField.description)
            t.column(keywordField.description)
            t.unique(sharingGroupUUIDField.description, keywordField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> KeywordModel {
        return try KeywordModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            keyword: row[Self.keywordField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.keywordField.description <- keyword
        )
    }
}

extension KeywordModel {
    static func keywords(forSharingGroupUUID sharingGroupUUID: UUID, db: Connection) throws -> Set<String> {
        let keywordModels = try KeywordModel.fetch(db: db, where: KeywordModel.sharingGroupUUIDField.description == sharingGroupUUID)
        return Set<String>(keywordModels.map { $0.keyword })
    }
}

extension MediaItemAttributes {
    func addKeywordsToKeywordModelsIfNeeded(sharingGroupUUID: UUID, db: Connection) throws {
        let currentAlbumKeywords = try KeywordModel.keywords(forSharingGroupUUID: sharingGroupUUID, db: db)
        
        let miaKeywords = getKeywords(onlyThoseUsed: false)
        
        // Get the keywords that we haven't yet stored locally.
        let difference = miaKeywords.subtracting(currentAlbumKeywords)
        for keyword in difference {
            let newKeywordModel = try KeywordModel(db: db, sharingGroupUUID: sharingGroupUUID, keyword: keyword)
            try newKeywordModel.insert()
        }
    }
}
