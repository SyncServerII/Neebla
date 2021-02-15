
// Initial landing view, when the app first starts: Enable the user to sign in.
// Menu functionality adapted from https://github.com/Vidhyadharan24/SideMenu

import SwiftUI
import iOSShared

struct SignInScreen: View {
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)

    init() {
        // So the `signInView` can show alerts.
        Services.session.signInServices.userEvents = Services.session.userEvents
    }
    
    var body: some View {
        MenuNavBar(title: "Sign In") {
            VStack {
                if !Services.setupState.isComplete {
                    Text("Setup Failure!")
                        .background(Color.red)
                }

                Services.session.signInServices.signInView
            }
            .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        }
    }
}

#if DEBUG
struct PopularPhotosView_Previews : PreviewProvider {
    static var previews: some View {
        SignInScreen()
    }
}
#endif
