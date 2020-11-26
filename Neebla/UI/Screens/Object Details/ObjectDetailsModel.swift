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
    
    func getCommentFileModel() -> ServerFileModel? {
        guard let fileModels = try? ServerFileModel.getFilesFor(fileGroupUUID: object.fileGroupUUID, withFileLabel: commentFileLabel) else {
            return nil
        }
        
        guard fileModels.count == 1 else {
            return nil
        }
        
        return fileModels[0]
    }
}
