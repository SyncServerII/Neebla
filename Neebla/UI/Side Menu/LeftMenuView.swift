
// Adapted from https://github.com/BLCKBIRDS/Side-Menu--Hamburger-Menu--in-SwiftUI

import SwiftUI
import SFSafeSymbols

class MenuState: ObservableObject {
    @Published var displayed = false
}

struct MenuStateKey: EnvironmentKey {
    static let defaultValue: MenuState = MenuState()
}

extension EnvironmentValues {
    var menuState: MenuState {
        get {
            return self[MenuStateKey.self]
        }
        set {
            self[MenuStateKey.self] = newValue
        }
    }
}

struct LeftMenuView: View {
    @ObservedObject var viewModel:SignInViewModel
    @Environment(\.menuState) var menuState
    
    var body: some View {
        VStack(alignment: .leading) {
            MenuButtonView(viewModel: viewModel, menuItemName: "Albums", image: .rectangleStack, topPadding: 30, screen: Screen(.albums), canDisable: false)
            MenuButtonView(viewModel: viewModel, menuItemName: "Album Sharing", image: .envelope, topPadding: 30, screen: Screen(.albumSharing))
            MenuButtonView(viewModel: viewModel, menuItemName: "Settings", image: .gear, topPadding: 30, screen: Screen(.settings))
            MenuButtonView(viewModel: viewModel, menuItemName: "SignIn/Out", image: .person2, topPadding: 30, screen: Screen(.signIn), canDisable: false)
//#if DEBUG
//            MenuButtonView(viewModel: viewModel, menuItemName: "Developer", image: .eyeglasses, topPadding: 30, screen: Screen(.developer), canDisable: false)
//#endif
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 32/255, green: 32/255, blue: 32/255))
        .edgesIgnoringSafeArea(.all)
        .onAppear() {
            menuState.displayed = true
        }
        .onDisappear() {
            menuState.displayed = false
        }
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
    let screen: Screen
    
    init(viewModel:SignInViewModel, menuItemName: String, image: SFSymbol, topPadding: CGFloat, screen: Screen, canDisable: Bool = true) {
        self.viewModel = viewModel
        self.menuItemName = menuItemName
        self.image = image
        self.topPadding = topPadding
        self.canDisable = canDisable
        self.screen = screen
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.sideMenuCenterView.wrappedValue = AnyView(screen)
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
