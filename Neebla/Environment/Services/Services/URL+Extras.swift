//
//  URL+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/11/21.
//

import Foundation
import SQLite
import iOSShared

extension URL {
    func enableAccessInBackground() {
        /* By default, the NSFileProtectionKey is NSFileProtectionCompleteUntilFirstUserAuthentication and I think this is causing app crashes when it goes into the background.
         */
        let attributes = [ FileAttributeKey.protectionKey : FileProtectionType.none ]
        do {
            try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            logger.debug("SQLite db: attr: \(attr)")
        } catch let error {
            logger.error("\(error)")
        }
    }
}
