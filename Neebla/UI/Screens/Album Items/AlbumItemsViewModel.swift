
import Foundation
import SQLite
import Combine
import iOSShared
import iOSBasics
import SwiftUI

class AlbumItemsViewModel: ObservableObject {
    var moveItemsSpecifics: MoveItemsSpecifics {
        MoveItemsSpecifics(fileGroupsToMove: Array(itemsToChange), sourceSharingGroup: sharingGroupUUID, refreshAlbums: { [weak self] in
            guard let self = self else { return }
            self.objects = self.getItemsForAlbum(album: self.sharingGroupUUID)
        })
    }
    
    enum SheetToShow: Identifiable {        
        case activityController
        case picker(MediaPicker)
        case moveItemsToAnotherAlbum
        
        var id: Int {
            switch self {
            case .activityController:
                return 0
            case .picker:
                return 1
            case .moveItemsToAnotherAlbum:
                return 2
            }
        }
    }
    
    @Published var sheetToShow: SheetToShow?
    @Published var showCellDetails: Bool = false
    
    private var boundedCancel:BoundedCancel?
    
    @Published var loading: Bool = false {
        didSet {
            if oldValue == false && loading == true {
                if !Services.session.userIsSignedIn {
                    showAlert(AlertyHelper.alert(title: "Alert!", message: "Please sign in to sync!"))
                    loading = false
                    return
                }
                
                boundedCancel = BoundedCancel { [weak self] in
                    guard let self = self else { return }
                    
                    if self.loading {
                        self.loading = false
                    }
                }
                
                // Calling this user triggered. User initiated the pull to refresh.
                self.sync(userTriggered: true)
            }
        }
    }
    
    @Published var objects = [ServerObjectModel]()
    @Published var unfilteredNumberObjects: Int = 0
    
    let sharingGroupUUID: UUID
    
    enum ChangeMode {
        case sharing
        case moving
        case moveAll
        case none
    }
    
    @Published var changeMode:ChangeMode = .none {
        didSet {
            switch changeMode {
            case .none, .sharing, .moving:
                itemsToChange.removeAll()
            case .moveAll:
                let fileGroups = objects.map { $0.fileGroupUUID }
                itemsToChange = Set<UUID>(fileGroups)
            }
        }
    }
    
    func toggleSharingMode() {
        switch changeMode {
        case .moving, .sharing, .moveAll:
            changeMode = .none
        case .none:
            changeMode = .sharing
        }
    }

    func toggleMovingMode(moveAll: Bool) {
        switch changeMode {
        case .moving, .sharing, .moveAll:
            changeMode = .none
        case .none:
            if moveAll {
                changeMode = .moveAll
            }
            else {
                changeMode = .moving
            }
        }
    }

    func toggleItemToChange(fileGroupUUID: UUID) {
        if itemsToChange.contains(fileGroupUUID) {
            itemsToChange.remove(fileGroupUUID)
        }
        else {
            itemsToChange.insert(fileGroupUUID)
        }
    }
    
    // fileGroupUUID's of items to change
    @Published var itemsToChange = Set<UUID>()

    var sortFilterSettings: SortFilterSettings?
    var activityItems = [Any]()
    
    private var syncSubscription:AnyCancellable!
    private var markAsDownloadedSubscription:AnyCancellable!
    private var userEventSubscriptionOther:AnyCancellable!
    private var objectDeletedSubscription:AnyCancellable!
    private var settingsDiscussionFilterSubscription:AnyCancellable!
    private var settingsSortBySubscription:AnyCancellable!
    
    // Not quite sure why this is needed, but seemingly after navigating away from the album items screen for an album, the screen/model isn't necessarily deallocated. Retain cycle? Darn if I can see it though.
    var screenDisplayed = false
    
    var albumModel: AlbumModel?
    
    init(album sharingGroupUUID: UUID) {
        self.sharingGroupUUID = sharingGroupUUID
        
        do {
            let sortFilterSettings = try SortFilterSettings.getSingleton(db: Services.session.db)
            self.sortFilterSettings = sortFilterSettings

            // These subscriptions seem to get fired *before* the properties on the `sortFilterSettings` object change. So, have added parameters to `getItemsForAlbum` to deal with this.
            settingsDiscussionFilterSubscription = sortFilterSettings.discussionFilterByChanged.sink { [weak self] value in
                guard let self = self else { return }
                self.updateIfNeeded(self.getItemsForAlbum(album: sharingGroupUUID, discussionFilterBy: value))
            }
            
            settingsSortBySubscription = sortFilterSettings.sortByOrderAscendingChanged.sink { [weak self] value in
                guard let self = self else { return }
                
                // Don't use `updateIfNeeded`-- that doesn't respect the order of the values returned in `getItemsForAlbum`.
                self.objects = self.getItemsForAlbum(album: sharingGroupUUID, sortByOrderAscending: value)
            }
        } catch let error {
            logger.error("SortFilterSettings.getSingleton: \(error)")
        }
                
        syncSubscription = Services.session.serverInterface.sync.sink { [weak self] syncResult in
            guard let self = self else { return }
                        
            guard case .index(let sharingGroupUUID, _) = syncResult,
                sharingGroupUUID == self.sharingGroupUUID else {
                return
            }

            self.boundedCancel?.minimumCancel()

            do {
                // Reset the `needsDownload` field, if needed, after a successful sync.
                if self.screenDisplayed {
                    try DownloadIndicator.resetAfterSync(sharingGroupUUID: sharingGroupUUID)
                }
            }
            catch let error {
                logger.error("\(error)")
            }
            
            self.updateIfNeeded(self.getItemsForAlbum(album: sharingGroupUUID))
            logger.debug("Sync done")            
        }

        // Once files are downloaded, update our list. Debounce to avoid too many updates too quickly.
        markAsDownloadedSubscription = Services.session.serverInterface.objectMarkedAsDownloaded
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { [weak self] fileGroupUUID in
            guard let self = self else { return }
            self.updateIfNeeded(self.getItemsForAlbum(album: sharingGroupUUID))
        }
        
        // If an object is deleted that we're displaying, update the UI. Want to listen to both (a) a queue/deletion completing, and (b) a download deletion completing.
        objectDeletedSubscription = Services.session.serverInterface.deletionCompleted.sink { [weak self] fileGroupUUID in
            guard let self = self else { return }

            guard let fileGroupUUID = fileGroupUUID else {
                return
            }
            
            // Is this an object we care about on this screen?
            
            if let _ = try? ServerObjectModel.fetchSingleRow(db: Services.session.db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) {
                self.updateIfNeeded(self.getItemsForAlbum(album: sharingGroupUUID))
            }
        }
        
        userEventSubscriptionOther = Services.session.userEvents.alerty.sink { [weak self] _ in
            self?.loading = false
        }
        
        if Services.session.userIsSignedIn {
            sync()
        }
        
        // Give user something to look at if there are album items already. If this is the first time loading the album, user will see empty state for moment first.
        self.objects = getItemsForAlbum(album: sharingGroupUUID)
        logger.debug("self.objects.count: \(self.objects.count)")
        
        do {
            albumModel = try AlbumModel.fetchSingleRow(db: Services.session.db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroupUUID)
        } catch let error {
            logger.error("Could not fetch album: \(error)")
        }
    }
    
    deinit {
        logger.debug("AlbumItemsViewModel: deinit")
    }
    
    // This method had been the source of "flicker" on the screen for quite a while, until I changed the "==" operator be more specific.
    private func updateIfNeeded(_ update: [ServerObjectModel]) {
        let current = Set<ServerObjectModel>(objects)
        let new = Set<ServerObjectModel>(update)
        if current == new {
            // No update needed.
            return
        }
                
        self.objects = update
    }
    
    // If force is true, doesn't check if the model values have changed.
    private func getItemsForAlbum(album sharingGroupUUID: UUID, sortByOrderAscending: Bool? = nil, discussionFilterBy: SortFilterSettings.DiscussionFilterBy? = nil) -> [ServerObjectModel] {
    
        logger.debug("getItemsForAlbum")
        
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
            return objects.sorted { (object1, object2) -> Bool in
                return sortObjects(object1, object2)
            }
        }
        else {
            return []
        }
    }

    func sync(userTriggered: Bool = false) {
        // It seems odd to stay in a changing mode if user triggers a sync.
        if changeMode != .none {
            changeMode = .none
        }
        
        do {
            try Services.session.syncServer.sync(sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
            loading = false

            if let networkError = error as? Errors, networkError.networkIsNotReachable {
                if userTriggered {
                    showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                }
                return
            }
            
            showAlert(AlertyHelper.error(message: "Failed to sync."))
        }
    }
    
    func uploadNewItem(assets: UploadableMediaAssets) {
        do {
            try AnyTypeManager.session.uploadNewObject(assets: assets, sharingGroupUUID: sharingGroupUUID)
            
            // Don't rely on only a sync to update the view with the new media item. If there isn't a network connection, a sync won't do what we want.
        
            // This more directly updates the view from the local file that was added.
            updateIfNeeded(getItemsForAlbum(album: sharingGroupUUID))
            
            // Indicating this as *not* user triggered as it's not *directly* user triggered, and I don't want a no-network error showing up in this case. The upload, if we get this far, should have been successfully queued.
            sync()
        }
        catch let error {
            logger.error("error: \(error)")
        }
    }
    
    func shareActivityItems() -> [Any] {
        guard changeMode == .sharing else {
            logger.error("shareActivityItems but not sharing")
            return []
        }
        
        guard itemsToChange.count > 0 else {
            return []
        }
        
        // Map the fileGroupUUID for an object to its type, and then to the activityItem(s) for that object.
        
        var result = [Any]()
        
        for itemToShare in itemsToChange {
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
    
    func markAllRead() {
        // It seems odd to stay in sharing mode if user triggers a "Mark all read".
        if changeMode != .none {
            changeMode = .none
        }
        
        CommentCountsObserver.markAllRead(for: objects)
    }
    
    func restartDownload(fileGroupUUID: UUID) {
        var downloading = false
        
        logger.notice("restartDownload: Attempting for fileGroupUUID: \(fileGroupUUID)")
        
        do {
            downloading = try Services.session.syncServer.isQueued(.download, fileGroupUUID: fileGroupUUID)
        } catch let error {
            logger.error("\(error)")
        }
        
        guard downloading else {
            showAlert(AlertyHelper.alert(title: "Alert!", message: "Media item wasn't downloading. Use a long press to restart a media item download that is having a problem."))
            return
        }
        
        showAlert(AlertyHelper.customAction(title: "Restart download?",
            message: "Restart downloading the media item files?", actionButtonTitle: "Restart",
            action: {
                do {
                    try Services.session.syncServer.restart(download: fileGroupUUID)
                    showAlert(AlertyHelper.alert(title: "Success!", message: "Please do a pull-down refresh to complete the restart of the downloads."))
                } catch let error {
                    logger.error("restartDownload: \(error)")
                    showAlert(AlertyHelper.alert(title: "Alert!", message: "Could not restart download(s)."))
                }
            },
            cancelTitle: "Cancel"))
    }
}
