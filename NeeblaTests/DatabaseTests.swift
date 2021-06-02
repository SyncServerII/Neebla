//
//  DatabaseTests.swift
//  NeeblaTests
//
//  Created by Christopher G Prince on 6/1/21.
//

import XCTest
import SQLite
@testable import Neebla
import ServerShared

class DatabaseTests: XCTestCase {
    var database: Connection!
    
    override func setUpWithError() throws {
        database = try Connection(.inMemory)
        try AlbumModel.createTable(db: database)
        try AlbumModel.allMigrations(db: database)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLastSyncDateExpired_nilLastSyncDate() throws {
        let model = try AlbumModel(db: database, sharingGroupUUID: UUID(), albumName: "foo", permission: .admin, deleted: false, needsDownload: false, lastSyncDate: nil)
        XCTAssert(model.lastSyncDateHasExpired)
    }
    
    func testLastSyncDateExpired_recentLastSyncDate_today() throws {
        let model = try AlbumModel(db: database, sharingGroupUUID: UUID(), albumName: "foo", permission: .admin, deleted: false, needsDownload: false, lastSyncDate: Date())
        XCTAssert(!model.lastSyncDateHasExpired)
    }
    
    func testLastSyncDateExpired_recentLastSyncDate_yesterday() throws {
        let calendar = Calendar.current

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            XCTFail()
            return
        }
        
        let model = try AlbumModel(db: database, sharingGroupUUID: UUID(), albumName: "foo", permission: .admin, deleted: false, needsDownload: false, lastSyncDate: yesterday)
        XCTAssert(!model.lastSyncDateHasExpired)
    }
    
    func testLastSyncDateExpired_recentLastSyncDate_expired() throws {
        let calendar = Calendar.current

        guard let expired = calendar.date(byAdding: .day, value: -(ServerConstants.numberOfDaysUntilInformAllButSelfExpiry + 1), to: Date()) else {
            XCTFail()
            return
        }
        
        let model = try AlbumModel(db: database, sharingGroupUUID: UUID(), albumName: "foo", permission: .admin, deleted: false, needsDownload: false, lastSyncDate: expired)
        XCTAssert(model.lastSyncDateHasExpired)
    }
}
