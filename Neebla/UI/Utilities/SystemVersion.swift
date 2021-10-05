//
//  SystemVersion.swift
//  Neebla
//
//  Created by Christopher G Prince on 10/2/21.
//

import Foundation

enum SystemVersion {
    case iOS15
    
    // Returns true if system version or higher is available
    static func `available`(_ version: SystemVersion) -> Bool {
        switch version {
        case .iOS15:
            if #available(iOS 15, *) {
                return true
            }
            return false
        }
    }
}
