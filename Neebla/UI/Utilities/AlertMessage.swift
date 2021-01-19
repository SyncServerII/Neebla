
import Foundation
import SwiftUI
import iOSBasics
import Combine
import iOSShared

// This provides two kinds of user alert mechanisms. For both of these, the `.showUserAlert` modifier must be added to the View for the screen.
// a) Directly showing a message by a screen: Just set the `userAlert` property of the `UserAlertModel`.
// b) Indirectly, through a subscription set up by `setupHandleUserEvents`. These are for `UserEvent`'s from the iOSBasics package.

protocol UserAlertMessage: UserAlertDelegate {
    var screenDisplayed: Bool { get set }
}

class UserAlertModel: ObservableObject, UserAlertMessage {
    public var screenDisplayed: Bool = false
    @Published public var show: Bool = false
    
    public var userAlert: UserAlertContents? {
        didSet {
            // If we don't constrain this by whether or not the screen is displayed, when we navigate to other screens, we get the same error, once per screen-- because each screen model has an `errorSubscription`. I don't know if having these models remain allocated is standard behavior for SwiftUI, but currently it is the case.
            DispatchQueue.main.async {
                self.show = self.userAlert != nil && self.screenDisplayed
            }
        }
    }
    
    public init() {}
}

extension UserAlertMessage {
    func showMessage(for userEvent: UserEvent?) {
        switch userEvent {
        case .error(let error):
            if let error = error {
                userAlert = .error(message: "\(error)")
            }
            else {
                userAlert = .titleOnly("Error!")
            }
            
        case .showAlert(title: let title, message: let message):
            userAlert = .titleAndMessage(title: title, message: message)

        case .none:
            // This isn't an error
            break
        }
    }
}

protocol ModelAlertDisplaying: AnyObject {
    var userEventSubscription:AnyCancellable! {get set}
    var userAlertModel:UserAlertModel {get}
}

extension ModelAlertDisplaying {
    func setupHandleUserEvents() {
        userEventSubscription = Services.session.serverInterface.$userEvent.sink { [weak self] event in
            guard let self = self else { return }
            guard self.userAlertModel.screenDisplayed else {
                return
            }
            
            logger.debug("setupHandleUserEvents: \(String(describing: event))")
            self.userAlertModel.showMessage(for: event)
        }
    }
}

extension View {
    func showUserAlert(show: Binding<Bool>, message:UserAlertMessage) -> some View {
        self.alert(isPresented: show, content: {
            switch message.userAlert {
            case .titleAndMessage(title: let title, message: let message):
                return Alert(title: Text(title), message: Text(message))
            case .titleOnly(let title):
                return Alert(title: Text(title))
            case .error(message: let message):
                return Alert(title: Text("Error!"), message: Text(message))
            
            case .customAction(title: let title, message: let message, actionButtonTitle: let actionButtonTitle, action: let action):
                let cancel = Alert.Button.cancel()
                let defaultButton = Alert.Button.default(
                    Text(actionButtonTitle),
                    action: {
                        action()
                    }
                )
                return Alert(title: Text(title), message: Text(message), primaryButton: defaultButton, secondaryButton: cancel)
            
            case .customDetailedAction(let title, let message, let actionButtonTitle, let action, let cancelTitle, let cancelAction):
                let cancel = Alert.Button.cancel(Text(cancelTitle)) {
                    cancelAction()
                }
                let defaultButton = Alert.Button.default(
                    Text(actionButtonTitle),
                    action: {
                        action()
                    }
                )
                return Alert(title: Text(title), message: Text(message), primaryButton: defaultButton, secondaryButton: cancel)

            case .none:
                return Alert(title: Text("Error!"))
            }
        })
        .onAppear() {
            message.screenDisplayed = true
        }
        .onDisappear() {
            message.screenDisplayed = false
            
            // I had been getting duplicate error messages. e.g., on sharing account creation by an invitation. This is to avoid this.
            message.userAlert = nil
        }
    }
}
