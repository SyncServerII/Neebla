//
//  SetupLocalDatabase.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/17/21.
//

// Database tables used only in main app.

import Foundation
import SQLite

struct SetupLocalDatabase {
    static func setup(db: Connection) throws {
        try SortFilterSettings.setupSingleton(db: db)
    }
}
