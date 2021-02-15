//
//  ShowAlert.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/14/21.
//

import Foundation
import SwiftUI
import iOSShared

// Global to make it easier to use-- it'll be used alot.

func showAlert(_ alert: SwiftUI.Alert) {
    Services.session.userEvents.alerty.send(AlertyContents(alert))
}
