//
//  ImageIconModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/15/20.
//

import Foundation
import SQLite
import UIKit

class ImageIconModel {
    let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel

    private func getFilesFor(fileGroupUUID: UUID) throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
    }
    
    // completion handler called async on the main thread.
    func loadImage(fileGroupUUID: UUID, completion:@escaping (UIImage)->()) {
        guard let fileModels = try? getFilesFor(fileGroupUUID: fileGroupUUID) else {
            return
        }
        
        let filter = fileModels.filter { $0.fileLabel == imageFileLabel}
        guard filter.count == 1 else {
            return
        }
        let imageFileModel = filter[0]
        
        if let imageFileURL = imageFileModel.url {
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: imageFileURL),
                    let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                }
            }
        }
    }
}
