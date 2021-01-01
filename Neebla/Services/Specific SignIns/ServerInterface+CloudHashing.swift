
import Foundation
import iOSShared
import iOSDropbox
import iOSGoogle

extension ServerInterface {
    func addHashingForCloudStorageSignIns(hashingManager: HashingManager) throws {
        try hashingManager.add(hashing: DropboxHashing())
        try hashingManager.add(hashing: GoogleHashing())
    }
}
