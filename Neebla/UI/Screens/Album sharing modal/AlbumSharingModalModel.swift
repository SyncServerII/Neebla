
import Foundation
import SwiftUI
import Combine

class AlbumSharingModalModel: ObservableObject, ModelAlertDisplaying {
    var errorSubscription: AnyCancellable!
    var userAlertModel: UserAlertModel
    
    init(sharingGroupUUID: UUID, userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
    }
}
