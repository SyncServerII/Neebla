
import Foundation
import SwiftUI
import Combine

class SignInScreenModel: ObservableObject, ModelAlertDisplaying {
    @Published var userAlertModel:UserAlertModel
    var errorSubscription:AnyCancellable!

    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
    }
}
