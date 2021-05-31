//
//  FileUpload+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 5/31/21.
//

import Foundation
import iOSBasics
import ServerShared

extension FileUpload {
    // Upload for files that should be visible (as downloadable items in albums) to other users but not self
    // Always sets `informAllButSelf` to true in the `FileUpload`.
    static func forOthers(fileLabel: String, mimeType: MimeType? = nil, dataSource: UploadDataSource, uuid: UUID, appMetaData: String? = nil) -> FileUpload {
        FileUpload(fileLabel: fileLabel, mimeType: mimeType, dataSource: dataSource, uuid: uuid, appMetaData: appMetaData, informAllButSelf: true)
    }
}
