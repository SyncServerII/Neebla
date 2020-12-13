
import Foundation
import SwiftUI
import iOSBasics
import Combine

protocol AlertMessage: AnyObject {
    var alertMessage: String? { get set }
}

// User Alert Messages are intended to be informational, and not require a decision on the part of the user. They can be positive (e.g., "A user was created." or negative (e.g. "A server request failed.").

enum UserAlertContents {
    case title(String)
    case full(title: String, message: String)
    
    // Shows "Error" as title
    case error(message: String)
}

protocol UserAlertMessage: AnyObject {
    var userAlert: UserAlertContents? { get set }
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
    @Published var show: Bool = false
    var userAlert: UserAlertContents? {
        didSet {
            show = userAlert != nil
        }
    }
}

protocol HandleErrors: AnyObject {
    var errorSubscription:AnyCancellable! {get set}
    var userAlertModel:UserAlertModel {get set}
}

extension HandleErrors {
    func setupHandleErrors() {
        errorSubscription = Services.session.serverInterface.$error.sink { [weak self] errorEvent in
            guard let self = self else { return }
            self.userAlertModel.showMessage(for: errorEvent)
        }
    }
}

extension View{
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
    }
}
