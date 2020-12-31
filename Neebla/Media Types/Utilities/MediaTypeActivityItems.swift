//
//  MediaTypeActivityItems.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/30/20.
//

// Generate one or more activity items that can be used with UIActivityViewController
// See also https://nshipster.com/uiactivityviewcontroller/

import Foundation

protocol MediaTypeActivityItems {
    func activityItems(forObject object: ServerObjectModel) throws -> [Any]
}
