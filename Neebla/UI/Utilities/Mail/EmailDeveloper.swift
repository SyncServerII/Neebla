//
//  EmailDeveloper.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/12/22.
//

import Foundation
import iOSShared
import MessageUI

class EmailDeveloper {
    static let developer = EmailContents(subject: "Question or comment for developer of Neebla", to: "chris@SpasticMuffin.biz")
    
    static func addLogs(vc: MFMailComposeViewController) {
        let archivedFileURLs = sharedLogging.archivedFileURLs
        guard archivedFileURLs.count > 0 else {
            return
        }
        
        for logFileURL in archivedFileURLs {
            guard let logFileData = try? Data(contentsOf: logFileURL, options: NSData.ReadingOptions()) else {
                continue
            }
            
            let fileName = logFileURL.lastPathComponent
            vc.addAttachmentData(logFileData, mimeType: "text/plain", fileName: fileName)
        }
    }
}
