//
//  Services+LocalDatabase.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/13/20.
//

import Foundation
import iOSShared
import SQLite
import SQLiteObjc

// "Local" database in the sense of "in app" (not remote, across network)

extension Services {
    func connectToLocalDatabase() throws {
        let dbURL = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.neeblaDatabase)
        logger.info("Neebla SQLite db: \(dbURL.path)")
        
        // For rationale for flag: https://github.com/stephencelis/SQLite.swift/issues/1042
        db = try Connection(dbURL.path, additionalFlags: SQLITE_OPEN_FILEPROTECTION_NONE)
        //dbURL.enableAccessInBackground()
    }
}

