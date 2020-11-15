//
//  MainView.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/29/20.
//

import SideMenu
import SwiftUI

struct MainView : View {
    @ObservedObject var viewModel = SignInViewModel()

    var body: some View {
        SideMenu(leftMenu: LeftMenuView(viewModel: viewModel),
               centerView: Screens.signIn)
    }
}
