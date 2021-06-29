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
    public static let m2021_06_01: Int32 = 2021_06_01
    public static let m2021_06_15: Int32 = 2021_06_15
    public static let m2021_06_27: Int32 = 2021_06_27
}

class Migration: VersionedMigrationRunner {
    // From my evaluation so far, using PersistentValue with user defaults doesn't work. See also https://github.com/sunshinejr/SwiftyUserDefaults/issues/282
    private static let _schemaVersionDeprecated = try! PersistentValue<Int>(name: "Neebla.MigrationController.schemaVersion", storage: .userDefaults)
    private static let _schemaVersion = try! PersistentValue<Int>(name: "Neebla.MigrationController.schemaVersion", storage: .file)
    
    // Migrate from using user defaults to using file-based storage with `PersistentValue`. Only does the migration if needed. Should be able remove this after getting a TestFlight build or two to Rod and Dany. Don't need to include this in final 2.0.0 release. Can remove `_schemaVersionDeprecated` then too.
    private func migrate() {
        if let value = Self._schemaVersionDeprecated.value,
            Self._schemaVersion.value == nil {
            Self._schemaVersion.value = value
        }
    }
    
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
        migrate()
    }
    
    static func all(db: Connection) -> [iOSShared.Migration] {
        return [
            MigrationObject(version: SpecificMigration.m2021_5_8, apply: {
                try ServerFileModel.migration_2021_5_8(db: db)
            }),
            MigrationObject(version: SpecificMigration.m2021_06_01, apply: {
                try AlbumModel.migration_2021_6_1(db: db)
            }),
            MigrationObject(version: SpecificMigration.m2021_06_15, apply: {
                try ServerFileModel.migration_2021_6_15(db: db)
            }),
            MigrationObject(version: SpecificMigration.m2021_06_27, apply: {
                try ServerFileModel.migration_2021_6_27(db: db)
            })
        ]
    }
}
