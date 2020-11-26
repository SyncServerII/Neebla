//
//  ObjectDetailsModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/24/20.
//

import Foundation
import SQLite

class ObjectDetailsModel: ObservableObject {
    let commentFileLabel = FileLabels.comments
    let object: ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    private func getFilesFor(fileGroupUUID: UUID) throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
    }
    
    func getCommentFileModel() -> ServerFileModel? {
        guard let filter = (try? getFilesFor(fileGroupUUID: object.fileGroupUUID).filter {$0.fileLabel == commentFileLabel}) else {
            return nil
        }
        
        guard filter.count == 1 else {
            return nil
        }
        
        return filter[0]
    }
}
