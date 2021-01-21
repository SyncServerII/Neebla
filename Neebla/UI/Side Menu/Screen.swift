//
//  Screen.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/29/20.
//

import Foundation
import SwiftUI

struct Screen {
    let view: AnyView
    
    static var albums: Screen {
        Screen(view: AnyView(AlbumsScreen()))
    }
    
    static var albumSharing: Screen {
        Screen(view: AnyView(AlbumSharingScreen()))
    }
    
    static var settings: Screen {
        Screen(view: AnyView(SettingsScreen()))
    }
    
    static var signIn: Screen {
        Screen(view: AnyView(SignInScreen()))
    }
    
#if DEBUG
    static var developer: Screen {
        Screen(view: AnyView(DeveloperScreen()))
    }
#endif
}
