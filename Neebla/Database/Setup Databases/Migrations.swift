//
//  Migration.swift
//  Neebla
//
//  Created by Christopher G Prince on 5/8/21.
//

import Foundation
import iOSShared
import SQLite
import PersistentValue

enum SpecificMigration {
    public static let m2021_5_8: Int32 = 2021_5_8
}

class Migration: VersionedMigrationRunner {
    private static let _schemaVersion = try! PersistentValue<Int>(name: "Neebla.MigrationController.schemaVersion", storage: .userDefaults)
    
    static var schemaVersion: Int32? {
        get {
            if let value = _schemaVersion.value {
                return Int32(value)
            }
            return 0
        }
        
        set {
            if let value = newValue {
                _schemaVersion.value = Int(value)
            }
            else {
                _schemaVersion.value = nil
            }
        }
    }
    
    let db: Connection
    
    init(db:Connection) throws {
        self.db = db
    }
    
    static func all(db: Connection) -> [iOSShared.Migration] {
        return [
            MigrationObject(version: SpecificMigration.m2021_5_8, apply: {
                try ServerFileModel.migration_2021_5_8(db: db)
            })
        ]
    }
}
