
import Foundation
import SQLite
import Combine
import iOSShared
import iOSBasics

class AlbumItemsViewModel: ObservableObject, ModelAlertDisplaying {
    enum SheetToShow: Identifiable {        
        case activityController
        case picker(MediaPicker)
        
        var id: Int {
            switch self {
            case .activityController:
                return 0
            case .picker:
                return 1
            }
        }
    }
    
    @Published var sheetToShow: SheetToShow?
    
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
    @Published var unfilteredNumberObjects: Int = 0
    
    let sharingGroupUUID: UUID
    
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
    
    var sortFilterSettings: SortFilterSettings?
    var activityItems = [Any]()
    
    private var syncSubscription:AnyCancellable!
    var userEventSubscription:AnyCancellable!
    private var markAsDownloadedSubscription:AnyCancellable!
    private var userEventSubscriptionOther:AnyCancellable!
    private var objectDeletedSubscription:AnyCancellable!
    private var settingsDiscussionFilterSubscription:AnyCancellable!
    private var settingsSortBySubscription:AnyCancellable!

    init(album sharingGroupUUID: UUID, userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        self.sharingGroupUUID = sharingGroupUUID
        
        do {
            let sortFilterSettings = try SortFilterSettings.getSingleton(db: Services.session.db)
            self.sortFilterSettings = sortFilterSettings

            // These subscriptions seem to get fired *before* the properties on the `sortFilterSettings` object change. So, have added parameters to `getItemsForAlbum` to deal with this.
            settingsDiscussionFilterSubscription = sortFilterSettings.$discussionFilterBy.sink { [weak self] value in
                guard let self = self else { return }
                self.getItemsForAlbum(album: sharingGroupUUID, discussionFilterBy: value, force: true)
            }
            
            settingsSortBySubscription = sortFilterSettings.$sortByOrderAscending.sink { [weak self] value in
                self?.getItemsForAlbum(album: sharingGroupUUID, sortByOrderAscending: value, force: true)
            }
        } catch let error {
            logger.error("SortFilterSettings.getSingleton: \(error)")
        }
        
        setupHandleUserEvents()
        
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
        
        userEventSubscriptionOther = Services.session.serverInterface.$userEvent.sink { [weak self] _ in
            self?.loading = false
        }
        
        sync()
        
        // Give user something to look at if there are album items already.
        getItemsForAlbum(album: sharingGroupUUID)
    }
    
    // If force is true, doesn't check if the model values have changed.
    private func getItemsForAlbum(album sharingGroupUUID: UUID, sortByOrderAscending: Bool? = nil, discussionFilterBy: SortFilterSettings.DiscussionFilterBy? = nil, force: Bool = false) {
        var ascending: Bool = true
        var fetchConstraint: SQLite.Expression<Bool> =
            ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
            ServerObjectModel.deletedField.description == false
            
        // First figure out number of rows, without any filter. Need that for screen display in some cases.
        if let numberObjects = try? ServerObjectModel.numberRows(db: Services.session.db, where: fetchConstraint) {
            if unfilteredNumberObjects != numberObjects {
                unfilteredNumberObjects = numberObjects
            }
        }
        
        if let settings = sortFilterSettings {
            ascending = sortByOrderAscending ?? settings.sortByOrderAscending
            
            switch (discussionFilterBy ?? settings.discussionFilterBy) {
            case .none:
                break
            case .onlyUnread:
                fetchConstraint =
                    ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
                    ServerObjectModel.deletedField.description == false &&
                    ServerObjectModel.unreadCountField.description > 0
            }
        }
                
        func sortObjects(_ o1:ServerObjectModel, _ o2: ServerObjectModel) -> Bool {
            if ascending {
                return o1.creationDate < o2.creationDate
            }
            else {
                return o1.creationDate > o2.creationDate
            }
        }
        
        if let objects = try? ServerObjectModel.fetch(db: Services.session.db, where: fetchConstraint) {
            if !force {
                let current = Set<ServerObjectModel>(self.objects)
                let new = Set<ServerObjectModel>(objects)
                if current == new {
                    // No update needed.
                    return
                }
            }
            
            self.objects = objects.sorted { (object1, object2) -> Bool in
                return sortObjects(object1, object2)
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
    
    func uploadNewItem(assets: UploadableMediaAssets) {
        do {
            try AnyTypeManager.session.uploadNewObject(assets: assets, sharingGroupUUID: sharingGroupUUID)
            
            // Don't rely on only a sync to update the view with the new media item. If there isn't a network connection, a sync won't do what we want.
        
            // This more directly updates the view from the local file that was added.
            getItemsForAlbum(album: sharingGroupUUID)
            
            sync()
        }
        catch let error {
            logger.error("error: \(error)")
        }
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
