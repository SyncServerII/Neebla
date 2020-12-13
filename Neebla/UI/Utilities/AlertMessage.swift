
import Foundation
import SwiftUI
import iOSBasics
import Combine

// User Alert Messages are intended to be informational, and not require a decision on the part of the user. They can be positive (e.g., "A user was created." or negative (e.g. "A server request failed.").

enum UserAlertContents {
    case title(String)
    case full(title: String, message: String)
    
    // Shows "Error" as title
    case error(message: String)
}

protocol UserAlertMessage: AnyObject {
    var userAlert: UserAlertContents? { get set }
    var screenDisplayed: Bool { get set }
}

extension UserAlertMessage {
    func showMessage(for errorEvent: ErrorEvent?) {
        switch errorEvent {
        case .error(let error):
            if let error = error {
                userAlert = .error(message: "\(error)")
            }
            else {
                userAlert = .title("Error!")
            }
            
        case .showAlert(title: let title, message: let message):
            userAlert = .full(title: title, message: message)

        case .none:
            // This isn't an error
            break
        }
    }
}

class UserAlertModel: ObservableObject, UserAlertMessage {
    var screenDisplayed: Bool = false
    @Published var show: Bool = false
    
    var userAlert: UserAlertContents? {
        didSet {
            // If we don't constrain this by whether or not the screen is displayed, when we navigate to other screens, we get the same error, once per screen-- because each screen model has an `errorSubscription`. I don't know if having these models remain allocated is standard behavior for SwiftUI, but currently it is the case.
            show = userAlert != nil && screenDisplayed
        }
    }
}

protocol ModelAlertDisplaying: AnyObject {
    var errorSubscription:AnyCancellable! {get set}
    var userAlertModel:UserAlertModel {get}
}

extension ModelAlertDisplaying {
    func setupHandleErrors() {
        errorSubscription = Services.session.serverInterface.$error.sink { [weak self] errorEvent in
            guard let self = self else { return }
            self.userAlertModel.showMessage(for: errorEvent)
        }
    }
}

extension View {
    func showUserAlert(show: Binding<Bool>, message:UserAlertMessage) -> some View {
        self.alert(isPresented: show, content: {
            switch message.userAlert {
            case .full(title: let title, message: let message):
                return Alert(title: Text(title), message: Text(message), dismissButton: nil)
            case .title(let title):
                return Alert(title: Text(title))
            case .error(message: let message):
                return Alert(title: Text("Error!"), message: Text(message), dismissButton: nil)
            case .none:
                return Alert(title: Text("Error!"))
            }
        })
        .onAppear() {
            message.screenDisplayed = true
        }
        .onDisappear() {
            message.screenDisplayed = false
        }
    }
}
