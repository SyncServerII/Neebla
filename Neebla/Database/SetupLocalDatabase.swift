//
//  SetupLocalDatabase.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/13/20.
//

import Foundation
import SQLite

struct SetupLocalDatabase {
    static func setup(db: Connection) throws {
        try AlbumModel.createTable(db: db)
        try ServerObjectModel.createTable(db: db)
        try ServerFileModel.createTable(db: db)
        
        try SettingsModel.createTable(db: db)
        try SettingsModel.initializeSingleton(db: db)
    }
}
