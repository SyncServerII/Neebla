//
//  ObjectDetailsModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/24/20.
//

import Foundation
import SQLite

class ObjectDetailsModel: ObservableObject {
    let object: ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    func getCommentFileModel() -> ServerFileModel? {
        return try? ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: object.fileGroupUUID)
    }
}
