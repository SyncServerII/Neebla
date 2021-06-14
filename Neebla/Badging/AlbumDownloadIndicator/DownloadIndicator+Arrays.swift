//
//  DownloadIndicator+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 5/30/21.
//

import Foundation
import iOSBasics
import ServerShared

extension Array where Element == iOSBasics.SharingGroup.FileGroupSummary.Inform {
    // Given an array of all Inform elements for a file, determine if the user needs to be informed about this change.
    private func informUserAboutFile() throws -> Bool {
        guard self.count > 0 else {
            return false
        }
        
        let fileUUID = self[0].fileUUID
        let fileAttributes = try Services.session.syncServer.fileAttributes(forFileUUID: fileUUID)
        
        var sortedFiles = self.sorted { i1, i2 in
            return i1.fileVersion < i2.fileVersion
        }
        
        // Checking against the serverVersion here because that reflects the sync'ed state. After a sync, assuming no other change, `informUserAboutFile` will return false.
        if let currentFileVersion = fileAttributes?.serverVersion {
            // We have a current version of the file. See if there are updates the user needs to be informed about.
            // Find the version in the sorted list.

            while sortedFiles.count > 0 {
                if sortedFiles[0].fileVersion <= currentFileVersion {
                    sortedFiles.removeFirst()
                }
                else {
                    break
                }
            }
        }
            
        guard sortedFiles.count > 0 else {
            return false
        }
        
        while sortedFiles.count > 0 {
            if sortedFiles[0].inform == .self {
                return true
            }
            else {
                sortedFiles.removeFirst()
            }
        }
        
        return false
    }
}

enum InformUserResult {
    case doNotInform
    case inform
    case noInformRecords
}
    
extension Array where Element == iOSBasics.SharingGroup.FileGroupSummary {
    // Given an array of all Inform elements for a file, determine if the user needs to be informed about this change.
    func informUserAboutSharingGroup() throws -> InformUserResult {
        var haveSomeInformRecords = false
        
        for summary in self {
            // `inform` is for a specific file group, i.e., "object".
            if let inform = summary.inform, inform.count > 0 {
                haveSomeInformRecords = true
                let informByFiles = Partition.array(inform, using: \.fileUUID)

                for informByFile in informByFiles {
                    if try informByFile.informUserAboutFile() {
                        return .inform
                    }
                }
            }
        }
        
        return haveSomeInformRecords ? .doNotInform : .noInformRecords
    }
}
