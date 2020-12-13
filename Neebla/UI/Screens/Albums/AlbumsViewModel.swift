
import Foundation
import Combine
import iOSShared

class AlbumsViewModel: ObservableObject, ModelAlertDisplaying {
    @Published var isShowingRefresh = false
    
    @Published var sharingMode = false
    @Published var presentAlbumSharingModal = false
    @Published var albumToShare: UUID?
    
    @Published var albums = [AlbumModel]()
        
    @Published var presentTextInput = false
    @Published var textInputAlbumName: String?
    @Published var textInputInitialAlbumName: String?
    @Published var textInputPriorAlbumName: String?
    @Published var textInputActionButtonName: String?
    @Published var textInputNewAlbum: Bool = false
    @Published var textInputTitle: String?
    var textInputAction: (()->())?
    
    static let untitledAlbumName = "Untitled Album"
    private var syncSubscription:AnyCancellable!
    var errorSubscription:AnyCancellable!
    let userAlertModel:UserAlertModel
    
    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
        
        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            
            self.isShowingRefresh = false
            self.getCurrentAlbums()
        }
        
        getCurrentAlbums()
    }

    func getCurrentAlbums() {
        if let albums = try? AlbumModel.fetch(db: Services.session.db) {
            self.albums = albums.sorted(by: { (a1, a2) -> Bool in
                let name1 = a1.albumName ?? Self.untitledAlbumName
                let name2 = a2.albumName ?? Self.untitledAlbumName
                return name1 < name2
            })
        }
        else {
            self.albums = []
        }
    }
    
    private func createNewAlbum(newAlbumName: String?) {
        let newSharingGroupUUID = UUID()
        
        Services.session.serverInterface.syncServer.createSharingGroup(sharingGroupUUID: newSharingGroupUUID, sharingGroupName: newAlbumName) { [weak self] error in
            guard let self = self else { return }

            guard error == nil else {
                self.userAlertModel.userAlert = .error(message: "Failed to create album.")
                return
            }
            
            self.sync()
        }
    }
    
    private func changeAlbumName(sharingGroupUUID: UUID, changedAlbumName: String?) {
        var changedAlbumName = changedAlbumName
        if changedAlbumName == "" {
            // So we get default title
            changedAlbumName = nil
        }
        
        Services.session.serverInterface.syncServer.updateSharingGroup(sharingGroupUUID: sharingGroupUUID, newSharingGroupName: changedAlbumName) { error in
            guard error == nil else {
                self.userAlertModel.userAlert = .error(message: "Failed to change album name.")
                return
            }
            
            self.sync()
        }
    }
    
    func sync() {
        do {
            try Services.session.syncServer.sync()
        } catch let error {
            logger.error("\(error)")
            isShowingRefresh = false
            userAlertModel.userAlert = .error(message: "Failed to sync.")
        }
    }
    
    func startChangeExistingAlbumName(sharingGroupUUID: UUID, currentAlbumName: String?) {
        textInputTitle = "Change Album Name:"
        textInputActionButtonName = "Change"
        
        textInputAction = { [weak self] in
            guard let self = self else { return }
            let changedAlbumName = self.textInputAlbumName ?? Self.untitledAlbumName
            self.changeAlbumName(sharingGroupUUID: sharingGroupUUID, changedAlbumName: changedAlbumName)
        }
        
        textInputInitialAlbumName = currentAlbumName ?? Self.untitledAlbumName
        textInputAlbumName = nil
        textInputPriorAlbumName = currentAlbumName
        textInputNewAlbum = false
        presentTextInput = true
    }
    
    func startCreateNewAlbum() {
        textInputTitle = "New Album Name:"
        textInputActionButtonName = "Create"

        textInputAction = { [weak self] in
            guard let self = self else { return }
            let newAlbumName = self.textInputAlbumName ?? Self.untitledAlbumName
            self.createNewAlbum(newAlbumName: newAlbumName)
        }
        
        textInputInitialAlbumName = Self.untitledAlbumName
        textInputAlbumName = nil
        textInputNewAlbum = true
        presentTextInput = true
    }
}
