//
//  Services+LocalDatabase.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/13/20.
//

import Foundation
import iOSShared
import SQLite

// "Local" database in the sense of "in app" (not remote, across network)

extension Services {
    func connectToLocalDatabase() throws {
        let dbURL = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.neeblaDatabase)
        logger.info("Neebla SQLite db: \(dbURL.path)")
        db = try Connection(dbURL.path)
    }
}

