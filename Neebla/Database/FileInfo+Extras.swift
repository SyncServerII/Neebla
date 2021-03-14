
import Foundation
import SQLite
import iOSBasics
import iOSShared

extension Array where Element == IndexObject {
    func upsert(db: Connection) throws {
        guard count > 0 else {
            return
        }
        
        for object in self {
            let objectUpsertResult = try ServerObjectModel.upsert(db: db, indexObject: object)

            for file in object.downloads {
                try ServerFileModel.upsert(db: db, file: file, object: object)
            }
            
            // This doesn't have to come after `ServerFileModel.upsert`, but just seems to make sense in reading.
            switch objectUpsertResult {
            case .firstTimeDeletion:
                do {
                    try Services.session.syncServer.markAsDeletedLocally(object: object.fileGroupUUID)
                } catch let error {
                    logger.error("Error calling markAsDeletedLocally: \(error)")
                }
            case .none:
                break
            }
        }
    }
}
