//
//  Screen.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/29/20.
//

import Foundation
import SwiftUI

enum ScreenType {
    case albums
    case albumSharing
    case settings
    case signIn
//#if DEBUG
//    case developer
//#endif
}

struct Screen: View {
    let type: ScreenType
    
    init(_ type: ScreenType) {
        self.type = type
    }
    
    var body: some View {
        switch type {
        case .albums:
            AlbumsScreen()
        case .albumSharing:
            AlbumSharingScreen()
        case .settings:
            SettingsScreen()
        case .signIn:
            SignInScreen()
//#if DEBUG
//        case .developer:
//            DeveloperScreen()
//#endif
        }
    }
}
