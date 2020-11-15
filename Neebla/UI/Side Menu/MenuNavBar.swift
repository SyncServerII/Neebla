
import SwiftUI
import SFSafeSymbols
import SideMenu

// Contains a `NavigationView`. You can embed `NavigationLink`'s inside after you use it.
struct MenuNavBar<Content: View>: View {
    @Environment(\.sideMenuLeftPanelKey) var sideMenuLeftPanel
    let title: String
    let content: Content
    let rightNavbarButton:AnyView?
    let leftMenuNav:Bool
    
    init(title: String, leftMenuNav:Bool = true, rightNavbarButton:AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.title = title
        self.rightNavbarButton = rightNavbarButton
        self.leftMenuNav = leftMenuNav
    }

    /* Debugging-- problem with background color of sign-in view.
    
        1) With the VStack and content in the NavigationView, I get the background color in the sign-in.
        2) Will *any* view in the NavigationView here have this same gray-ish background?
            a) Just a Rectangle() has a *black* background.
        3) In the iOSSignIns, SignInList, change:
            List(signIns) { signIn in
                Text("Some text")
                //SignInRow(description: signIn)
            }
            But get same issue.
        4) Replace list with just several Text's.
                var body: some View {
                    VStack {
                        Text("Some text1")
                        Text("Some text2")
                    }
            //        List(signIns) { signIn in
            //            Text("Some text")
            //            //SignInRow(description: signIn)
            //        }
                }
        5) Now, the background color is gone. It seems that issue is a List contained within a NavigationView.
        BUT: How to control the color?
        See also https://stackoverflow.com/questions/56503479/swiftui-how-do-you-change-the-tint-color-background-color-of-a-navigationview
     */
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                self.content
            }
            .navigationBarTitle(title, displayMode: .inline)
                .navigationBarItems(
                    leading: (
                        VStack {
                            if leftMenuNav {
                                Button(action: {
                                    withAnimation {
                                        self.sideMenuLeftPanel.wrappedValue = !self.sideMenuLeftPanel.wrappedValue
                                    }
                                }, label: {
                                    Image(systemName: SFSymbol.lineHorizontal3.rawValue)
                                        .accentColor(.blue)
                                        .imageScale(.large)
                                        // The tappable area is too small; fat fingering. Trying to make it larger.
                                        .frame(width: 75, height: 50)
                                })
                            }
                            else {
                                Rectangle().fill(Color.clear)
                            }
                        }
                    ), trailing:
                        rightNavbarButton
            )
        }
    }
}

