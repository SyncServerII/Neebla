//
//  ServerInterface+Helpers.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/3/20.
//

import Foundation
import iOSShared
import ServerShared
import iOSBasics

extension ServerInterface {
    func syncHelper(result: SyncResult) throws {
        switch result {
        case .noIndex:
            break
        case .index(sharingGroupUUID: _, index: let index):
            try index.upsert(db: Services.session.db)
        }

        let sharingGroups = try self.syncServer.sharingGroups()
        try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: sharingGroups)
    }
}
