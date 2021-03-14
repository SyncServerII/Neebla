//
//  UserDisplayable.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/14/21.
//

import Foundation

protocol UserDisplayable: Error {
    var userDisplayableMessage: (title: String, message: String)? { get }
}

extension UserDisplayable {
    static var badAspectRatio: (title: String, message: String) {
        return (title: "Alert!", message: "That image has a bad aspect ratio and cannot be added to an album. Please select a different image.")
    }
}

