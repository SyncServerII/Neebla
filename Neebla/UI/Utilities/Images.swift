//
//  Images.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/14/21.
//

import Foundation

enum Images {
    static func shareIcon(lightMode: Bool) -> String {
        lightMode ? "Share" : "ShareDarkMode"
    }
}
