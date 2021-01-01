
import Foundation
import SwiftUI
import Combine
import iOSShared

class SignInScreenModel: ObservableObject, ModelAlertDisplaying {
    @Published var userAlertModel:UserAlertModel
    var userEventSubscription:AnyCancellable!

    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleUserEvents()
    }
}
