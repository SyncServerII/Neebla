//
//  MainView.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/29/20.
//

import SideMenu
import SwiftUI

// If no user is signed, show the LandingView for a moment.
// After that interval, show albums if the user is signed in.
// Or the sign in screen if not.

struct MainView : View {
    @ObservedObject var viewModel = SignInViewModel()
    
    var body: some View {
        // Delay for a known duration (`landingViewDisplayed`) + any additional delay needed to determine if a user is signed in.
        if viewModel.landingViewDisplayed || Services.session.signInServices.manager.userIsSignedIn == nil  {
            LandingView()
        }
        else {
            LeftMenu(viewModel: viewModel,
                screen: viewModel.userSignedIn ? .albums : .signIn)
        }
    }
}

private struct LeftMenu: View {
    @ObservedObject var viewModel:SignInViewModel
    let screen: Screen
    
    // Not using `SideMenu` menu items. Using our own.
    let config = SideMenuConfig(leftMenuItem: .none, rightMenuItem: .none)
    
    var body: some View {
        SideMenu(leftMenu: LeftMenuView(viewModel: viewModel),
                    centerView: screen.view, config: config)
    }
}
