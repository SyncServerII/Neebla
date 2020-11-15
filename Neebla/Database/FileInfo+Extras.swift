
import Foundation
import ServerShared
import SQLite

extension Array where Element == FileInfo {
    func upsert(db: Connection) throws {
        guard count > 0 else {
            return
        }
        
        let fileGroups = Partition.array(self, using: \.fileGroupUUID)
        
        for fileGroup in fileGroups {
            let firstFile = fileGroup[0]
            try ServerObjectModel.upsert(db: db, fileInfo: firstFile)
            
            for file in fileGroup {
                try ServerFileModel.upsert(db: db, fileInfo: file)
            }
        }
    }
}
