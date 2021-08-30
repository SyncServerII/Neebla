//
//  Background.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/19/21.
//

import Foundation
import iOSShared

class Background {
    let backgroundAsssertable:BackgroundAsssertable
    static let session = Background()
    
    private init() {
        if Bundle.isAppExtension {
            backgroundAsssertable = ExtensionBackgroundTask()
        }
        else {
            backgroundAsssertable = MainAppBackgroundTask()
        }
    }
}
