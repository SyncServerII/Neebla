//
//  OldAppImage.swift
//  Neebla
//
//  Created by Christopher G Prince on 5/8/21.
//

import Foundation

// Retrieve the image title, from appMetaData-- a means that early app versions used to store the image title.

// Example appMetaData: {"fileType":"image","discussionUUID":"BB610C4E-CD7B-454A-8EFF-6344D102F095","title":"Christopher G. Prince"}

private struct ImageAppMetaData: Codable {
    let title: String
}

class OldAppImage {
    static func getTitle(object: ServerObjectModel) throws -> String? {
        guard object.objectType == ObjectType.image.rawValue else {
            return nil
        }
        
        let imageFile = try ServerFileModel.getFileFor(fileLabel: ImageObjectType.imageDeclaration.fileLabel, withFileGroupUUID: object.fileGroupUUID)
        guard let appMetaDataString = imageFile.appMetaData,
            let data = appMetaDataString.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        let appMetaData = try decoder.decode(ImageAppMetaData.self, from: data)
        return appMetaData.title
    }
}
