
import Foundation
import SQLite
import Combine
import iOSShared
import iOSBasics

protocol AlertMessage: AnyObject {
    var alertMessage: String! { get set }
}

extension AlertMessage {
    func showMessage(for errorEvent: ErrorEvent?) {
        switch errorEvent {
        case .error(let error):
            if let error = error {
                alertMessage = "Error: \(error)"
            }
            else {
                alertMessage = "Error!"
            }
            
        case .showAlert(title: let title, message: let message):
            alertMessage = "\(title): \(message)"

        case .none:
            // This isn't an error
            break
        }
    }
}

class AlbumItemsViewModel: ObservableObject, AlertMessage {
    @Published var objects = [ServerObjectModel]()
    let sharingGroupUUID: UUID

    @Published var isShowingRefresh = false
    @Published var presentAlert = false

    var alertMessage: String! {
        didSet {
            presentAlert = alertMessage != nil
        }
    }
    
    @Published var addNewItem = false
    private var syncSubscription:AnyCancellable!
    private var errorSubscription:AnyCancellable!

    init(album sharingGroupUUID: UUID) {
        self.sharingGroupUUID = sharingGroupUUID
        
        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            
            self.isShowingRefresh = false
            self.getItemsForAlbum(album: sharingGroupUUID)
        }
        
        errorSubscription = Services.session.serverInterface.$error.sink { [weak self] errorEvent in
            guard let self = self else { return }
            self.showMessage(for: errorEvent)
        }
        
        getItemsForAlbum(album: sharingGroupUUID)
    }
    
    private func getItemsForAlbum(album sharingGroupUUID: UUID) {
        if let objects = try? ServerObjectModel.fetch(db: Services.session.db, where: ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID) {
            self.objects = objects
        }
        else {
            self.objects = []
        }
    }
    
    func sync() {
        do {
            try Services.session.syncServer.sync(sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
            isShowingRefresh = false
            alertMessage = "Failed to sync."
        }
    }
    
    func startNewAddItem() {
        addNewItem = true
    }
    
    func filesFor(fileGroupUUID: UUID) -> [ServerFileModel] {
        do {
            let fileModels = try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
            return fileModels
        } catch let error {
            logger.error("\(error)")
            alertMessage = "Failed to get files for object."
            return []
        }
    }
}
