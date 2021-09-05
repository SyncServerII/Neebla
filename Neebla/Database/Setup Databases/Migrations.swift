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
import iOSBasics

enum SpecificMigration {
    public static let m2021_5_8: Int32 = 2021_5_8
    public static let m2021_06_01: Int32 = 2021_06_01
    public static let m2021_06_15: Int32 = 2021_06_15
    public static let m2021_06_27: Int32 = 2021_06_27
    public static let m2021_07_01: Int32 = 2021_07_01
    public static let m2021_08_26: Int32 = 2021_08_26
    public static let m2021_08_27: Int32 = 2021_08_27
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
    
    // This must not have content changes, only column additions (and maybe deletions). See https://github.com/SyncServerII/Neebla/issues/26
    static func metadata(db: Connection) -> [iOSShared.Migration] {
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
            }),
            MigrationObject(version: SpecificMigration.m2021_07_01, apply: {
                try ServerObjectModel.migration_2021_7_1(db: db)
            }),
            MigrationObject(version: SpecificMigration.m2021_07_01, apply: {
                try KeywordModel.migration_2021_7_1(db: db)
            }),
            MigrationObject(version: SpecificMigration.m2021_08_26, apply: {
                try ServerObjectModel.migration_2021_8_26(db: db)
            })
        ]
    }
    
    // These migrations can only do content changes to rows. See https://github.com/SyncServerII/Neebla/issues/26
    static func content(db: Connection, syncServer: SyncServer) -> [iOSShared.Migration] {
        return [
            MigrationObject(version: SpecificMigration.m2021_08_27, apply: {
                try ServerObjectModel.migration_2021_8_27(db: db, syncServer: syncServer)
            })
        ]
    }
}
