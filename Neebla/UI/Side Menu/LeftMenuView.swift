
// Adapted from https://github.com/BLCKBIRDS/Side-Menu--Hamburger-Menu--in-SwiftUI

import SwiftUI
import SFSafeSymbols

struct LeftMenuView: View {
    @Environment(\.sideMenuLeftPanelKey) var sideMenuLeftPanel
    @Environment(\.sideMenuCenterViewKey) var sideMenuCenterView
    @ObservedObject var viewModel:SignInViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            MenuButtonView(viewModel: viewModel, menuItemName: "Albums", image: .rectangleStack, topPadding: 30, menuChoice: Screens.albums, canDisable: false)
            MenuButtonView(viewModel: viewModel, menuItemName: "Album Sharing", image: .envelope, topPadding: 30, menuChoice: Screens.albumSharing)
            MenuButtonView(viewModel: viewModel, menuItemName: "Settings", image: .gear, topPadding: 30, menuChoice: Screens.settings)
            MenuButtonView(viewModel: viewModel, menuItemName: "SignIn/Out", image: .person2, topPadding: 30, menuChoice: Screens.signIn, canDisable: false)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 32/255, green: 32/255, blue: 32/255))
        .edgesIgnoringSafeArea(.all)
    }
}

struct MenuButtonView: View {
    @Environment(\.sideMenuLeftPanelKey) var sideMenuLeftPanel
    @Environment(\.sideMenuCenterViewKey) var sideMenuCenterView
    @ObservedObject var viewModel:SignInViewModel
    let menuItemName: String
    let image: SFSymbol
    let topPadding: CGFloat
    let canDisable: Bool
    let menuChoice: AnyView
    
    init(viewModel:SignInViewModel, menuItemName: String, image: SFSymbol, topPadding: CGFloat, menuChoice: AnyView, canDisable: Bool = true) {
        self.viewModel = viewModel
        self.menuItemName = menuItemName
        self.image = image
        self.topPadding = topPadding
        self.canDisable = canDisable
        self.menuChoice = menuChoice
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.sideMenuCenterView.wrappedValue = menuChoice
                self.sideMenuLeftPanel.wrappedValue = false
            }
        }) {
            Image(systemName: image.rawValue)
                .imageScale(.large)
            Text(menuItemName)
        }
        .foregroundColor(.gray)
        .font(.headline)
        .padding(.top, topPadding)
        .disabled(disable())
        .opacity(disable() ? 0.5 : 1)
    }
    
    func disable() -> Bool {
        guard canDisable else {
            return false
        }
        
        return !viewModel.userSignedIn
    }
}

