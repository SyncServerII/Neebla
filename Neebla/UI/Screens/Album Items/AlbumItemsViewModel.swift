
import Foundation
import SQLite
import Combine
import iOSShared
import iOSBasics

class AlbumItemsViewModel: ObservableObject, ModelAlertDisplaying {
    let userAlertModel: UserAlertModel
    @Published var showCellDetails: Bool = false
    @Published var loading: Bool = false {
        didSet {
            if oldValue == false && loading == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.sync()
                }
            }
        }
    }
    
    @Published var objects = [ServerObjectModel]()
    let sharingGroupUUID: UUID
    
    @Published var addNewItem = false
    @Published var sharing = false {
        didSet {
            itemsToShare.removeAll()
        }
    }
    
    func toggleItemToShare(fileGroupUUID: UUID) {
        if itemsToShare.contains(fileGroupUUID) {
            itemsToShare.remove(fileGroupUUID)
        }
        else {
            itemsToShare.insert(fileGroupUUID)
        }
    }
    
    // fileGroupUUID's of items to share
    @Published var itemsToShare = Set<UUID>()
    
    var activityItems = [Any]()
    @Published var completeSharing:Bool = false
    
    private var syncSubscription:AnyCancellable!
    var errorSubscription:AnyCancellable!
    private var markAsDownloadedSubscription:AnyCancellable!
    private var objectDeletedSubscription:AnyCancellable!

    init(album sharingGroupUUID: UUID, userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        self.sharingGroupUUID = sharingGroupUUID
        setupHandleErrors()
        
        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            
            self.loading = false
            self.getItemsForAlbum(album: sharingGroupUUID)
            logger.debug("Sync done")            
        }

        // Once files are downloaded, update our list. Debounce to avoid too many updates too quickly.
        markAsDownloadedSubscription = Services.session.serverInterface.$objectMarkedAsDownloaded
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { [weak self] fileGroupUUID in
            guard let self = self else { return }
            self.getItemsForAlbum(album: sharingGroupUUID)
        }
        
        // If an object is deleted that we're displaying, update the UI. Want to listen to both (a) a queue/deletion completing, and (b) a download deletion completing.
        objectDeletedSubscription = Services.session.serverInterface.$deletionCompleted.sink { [weak self] fileGroupUUID in
            guard let self = self else { return }

            guard let fileGroupUUID = fileGroupUUID else {
                return
            }
            
            // Is this an object we care about on this screen?
            
            if let _ = try? ServerObjectModel.fetchSingleRow(db: Services.session.db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) {
                self.getItemsForAlbum(album: sharingGroupUUID)
            }
        }
    }
    
    private func getItemsForAlbum(album sharingGroupUUID: UUID) {
        if let objects = try? ServerObjectModel.fetch(db: Services.session.db, where: ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
            ServerObjectModel.deletedField.description == false) {
            self.objects = objects.sorted { (object1, object2) -> Bool in
                return object1.creationDate < object2.creationDate
            }
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
            loading = false
            userAlertModel.userAlert = .error(message: "Failed to sync.")
        }
    }
    
    func updateAfterAddingItem() {
        // Don't rely on only a sync to update the view with the new media item. If there isn't a network connection, a sync won't do what we want.
        
        // This more directly updates the view from the local file that was added.
        getItemsForAlbum(album: sharingGroupUUID)
        
        sync()
    }
    
    func startNewAddItem() {
        addNewItem = true
    }
    
    func shareActivityItems() -> [Any] {
        guard itemsToShare.count > 0 else {
            return []
        }
        
        // Map the fileGroupUUID for an object to its type, and then to the activityItem(s) for that object.
        
        var result = [Any]()
        
        for itemToShare in itemsToShare {
            guard let object = (objects.filter {$0.fileGroupUUID == itemToShare}).first else {
                logger.error("Could not find object!!")
                continue
            }

            do {
                let activityItems = try AnyTypeManager.session.activityItems(forObject: object)
                result += activityItems
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        return result
    }
}
