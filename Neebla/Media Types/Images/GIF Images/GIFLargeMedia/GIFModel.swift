//
//  GIFIconModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/12/21.
//

import Foundation
import UIKit
import iOSShared

class GIFModel {
    let gifFileLabel = GIFObjectType.gifDeclaration.fileLabel
    var gifData: Data?
    
    init(object: ServerObjectModel) {
        guard let imageFileModel = try? ServerFileModel.getFileFor(fileLabel: gifFileLabel, withFileGroupUUID: object.fileGroupUUID) else {
            logger.debug("GIFIconModel: No ServerFileModel")
            return
        }
        
        guard let gifURL = imageFileModel.url else {
            logger.debug("GIFIconModel: No URL for ServerFileModel")
            return
        }
        
        do {
            gifData = try Data(contentsOf: gifURL)
        }
        catch let error {
            logger.error("GIFIconModel: Could not load gif: \(error)")
        }
    }
}
