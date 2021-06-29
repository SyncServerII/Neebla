//
//  SetupDatabase.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/13/20.
//

// Database tables shared across main app and sharing extension.

import Foundation
import SQLite

struct SetupDatabase {
    static func setup(db: Connection) throws {
        try AlbumModel.createTable(db: db)
        try ServerObjectModel.createTable(db: db)
        try ServerFileModel.createTable(db: db)
        try KeywordModel.createTable(db: db)
        
        try SettingsModel.setupSingleton(db: db)
    }
}
