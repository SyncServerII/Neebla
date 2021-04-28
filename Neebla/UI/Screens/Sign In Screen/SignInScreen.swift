
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
                        .font(.title)
                        .background(Color.red)
                }
                else if DetectV1.session.isV1 {
                    Text("Please remove this app and then re-download the v2 Neebla app.")
                        .font(.title)
                }
                else {
                    Services.session.signInServices.signInView
                }
            }
            .alertyDisplayer(show: $alerty.show, subscriber: alerty)
            .onAppear() {
                if DetectV1.session.isV1 {
                    showAlert(AlertyHelper.alert(title: "Alert!", message: "You are trying to install the v2 Neebla app and you had the v1 app installed before. You must first remove the v1 app and then install the v2 app."))
                }
            }
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
