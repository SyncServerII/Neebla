
import Foundation
import SwiftUI
import iOSBasics
import Combine
import iOSShared

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
                return Alert(title: Text(title), message: Text(message))
            case .title(let title):
                return Alert(title: Text(title))
            case .error(message: let message):
                return Alert(title: Text("Error!"), message: Text(message))
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
