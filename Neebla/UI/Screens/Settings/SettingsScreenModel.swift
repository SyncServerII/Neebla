
import Foundation
import CoreGraphics
import SwiftUI
import Combine

class SettingsScreenModel:ObservableObject, ModelAlertDisplaying {
    var errorSubscription: AnyCancellable!
    @Published var userAlertModel: UserAlertModel
    @Published var showAlbumList: Bool = false
    
    init(userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
    }
}
