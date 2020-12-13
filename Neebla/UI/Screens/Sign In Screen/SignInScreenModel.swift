
import Foundation
import SwiftUI
import Combine

class SignInScreenModel: ObservableObject, HandleErrors {
    @Published var userAlertModel:UserAlertModel
    var errorSubscription:AnyCancellable!

    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
    }
}
