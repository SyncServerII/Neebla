
import Foundation
import CoreGraphics
import SwiftUI
import Combine
import iOSShared
import MessageUI

class SettingsScreenModel:ObservableObject, ModelAlertDisplaying {
    enum ShowSheet {
        case albumList
        case emailDeveloper
    }
    
    var userEventSubscription: AnyCancellable!
    @Published var userAlertModel: UserAlertModel
    @Published var showSheet: Bool = false
    @Published var sheet: ShowSheet?
    @Published var sendMailResult: Swift.Result<MFMailComposeResult, Error>? = nil

    init(userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleUserEvents()
    }
}
