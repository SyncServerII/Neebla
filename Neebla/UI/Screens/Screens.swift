//
//  Screens.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/29/20.
//

import Foundation
import SwiftUI

enum Screens {
    static let images = AnyView(AlbumsScreen())
    static let albumSharing = AnyView(SendInvitationScreen())
    static let settings = AnyView(SettingsScreen())
    static let signIn = AnyView(SignInScreen())
}