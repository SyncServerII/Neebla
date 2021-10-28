//
//  UserDisplayable+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/14/21.
//

import Foundation
import iOSShared

extension UserDisplayable {
    static var badSize: (title: String, message: String) {
        return (title: "Alert!", message: "That image has a bad size and cannot be added to an album. Please select a different image.")
    }
    
    static var movieTooBig: (title: String, message: String) {
        return (title: "Alert!", message: "That movie is too big! Please select a smaller one.")
    }
}

