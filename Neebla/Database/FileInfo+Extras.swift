
import Foundation
 import SQLite
import iOSBasics

extension Array where Element == IndexObject {
    func upsert(db: Connection) throws {
        guard count > 0 else {
            return
        }
        
        for object in self {
            try ServerObjectModel.upsert(db: db, indexObject: object)
            
            for file in object.downloads {
                try ServerFileModel.upsert(db: db, file: file, object: object)
            }
        }
    }
}
