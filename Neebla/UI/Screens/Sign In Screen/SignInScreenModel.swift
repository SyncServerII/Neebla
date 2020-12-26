
import Foundation
import SwiftUI
import Combine
import iOSShared

class SignInScreenModel: ObservableObject, ModelAlertDisplaying {
    @Published var userAlertModel:UserAlertModel
    var errorSubscription:AnyCancellable!

    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
    }
}
