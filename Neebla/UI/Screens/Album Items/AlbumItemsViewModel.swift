
import Foundation
import SQLite
import Combine
import iOSShared
import iOSBasics
import SwiftUI
import ServerShared

class AlbumItemsViewModel: ObservableObject {
    enum SheetToShow: Identifiable {        
        case activityController
        case picker(MediaPicker)
        case moveItemsToAnotherAlbum(MoveItemsSpecifics)
        
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
                itemsToChange = Set<ServerObjectModel>(objects)
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

    func toggleItemToChange(item: ServerObjectModel) {
        if itemsToChange.contains(item) {
            itemsToChange.remove(item)
        }
        else {
            itemsToChange.insert(item)
        }
    }
    
    // items to change
    @Published var itemsToChange = Set<ServerObjectModel>()

    var sortFilterSettings: SortFilterSettings?
    var activityItems = [Any]()
    
    private var syncSubscription:AnyCancellable!
    private var markAsDownloadedSubscription:AnyCancellable!
    private var objectDeletedSubscription:AnyCancellable!
    private var settingsDiscussionFilterSubscription:AnyCancellable!
    private var settingsSortByOrderSubscription:AnyCancellable!
    private var settingsSortOrderSubscription:AnyCancellable!
    private var updateDateListener: AnyObject!
    
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
            
            settingsSortByOrderSubscription = sortFilterSettings.sortByOrderAscendingChanged.sink { [weak self] value in
                guard let self = self else { return }
                
                // Don't use `updateIfNeeded`-- that doesn't respect the order of the values returned in `getItemsForAlbum`.
                self.objects = self.getItemsForAlbum(album: sharingGroupUUID, sortByOrderAscending: value)
            }
            
            settingsSortOrderSubscription = sortFilterSettings.sortByChanged.sink { [weak self] value in
                guard let self = self else { return }
                
                self.objects = self.getItemsForAlbum(album: sharingGroupUUID, sortBy: value)
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

        updateDateListener = NotificationCenter.default.addObserver(forName: ServerObjectModel.updateDateChanged, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            /* Before we update, check:
                1) Are we sorting currently by modification date? If not, disregard this change.
                2) Is the object that changed actually being displayed on the screen?
            */

            guard self.sortFilterSettings?.sortBy == .updateDate else {
                return
            }
            
            guard let fileGroupUUID = ServerObjectModel.getFileGroupUUID(from: notification) else {
                return
            }
            
            guard let _ = try? ServerObjectModel.fetchSingleRow(db: Services.session.db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) else {
                return
            }
            
            self.objects = self.getItemsForAlbum(album: sharingGroupUUID)
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
    private func getItemsForAlbum(album sharingGroupUUID: UUID, sortBy: SortFilterSettings.SortBy? = nil, sortByOrderAscending: Bool? = nil, discussionFilterBy: SortFilterSettings.DiscussionFilterBy? = nil) -> [ServerObjectModel] {
    
        logger.debug("getItemsForAlbum")
        
        var ascending: Bool = true
        var sortByOrder: SortFilterSettings.SortBy = .creationDate
        
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
            sortByOrder = sortBy ?? settings.sortBy
            
            switch (discussionFilterBy ?? settings.discussionFilterBy) {
            case .none:
                break

            case .newOrUnread:
                fetchConstraint =
                    ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
                    ServerObjectModel.deletedField.description == false &&
                    (ServerObjectModel.newField.description ||
                    ServerObjectModel.unreadCountField.description > 0)
                    
            case .onlyNew:
                fetchConstraint =
                    ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
                    ServerObjectModel.deletedField.description == false &&
                    ServerObjectModel.newField.description
                    
            case .onlyUnread:
                fetchConstraint =
                    ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
                    ServerObjectModel.deletedField.description == false &&
                    ServerObjectModel.unreadCountField.description > 0
            }
        }
                
        func sortObjects(_ o1:ServerObjectModel, _ o2: ServerObjectModel) -> Bool {
            switch sortByOrder {
            case .creationDate:
                if ascending {
                    return o1.creationDate < o2.creationDate
                }
                else {
                    return o1.creationDate > o2.creationDate
                }
            
            case .updateDate:
                if ascending {
                    return (o1.updateDate ?? o1.creationDate) < (o2.updateDate ?? o2.creationDate)
                }
                else {
                    return (o1.updateDate ?? o1.creationDate) > (o2.updateDate ?? o2.creationDate)
                }
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

    func refresh() {
        if !Services.session.userIsSignedIn {
            showAlert(AlertyHelper.alert(title: "Alert!", message: "Please sign in to sync!"))
            return
        }
        
        // Calling this user triggered. User initiated the pull to refresh.
        self.sync(userTriggered: true)
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
                
        var result = [Any]()
        
        for object in itemsToChange {
            do {
                let activityItems = try AnyTypeManager.session.activityItems(forObject: object)
                result += activityItems
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        return result
    }
    
    func markAllReadAndNotNew() {
        // It seems odd to stay in sharing mode if user triggers a "Mark all read".
        if changeMode != .none {
            changeMode = .none
        }
        
        do {
            try NewItemBadges.markAllNotNew(for: objects)
        } catch let error {
            logger.error("\(error)")
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

    func prepareMoveItemsToAnotherAlbum() {
        do {
            var usersMakingComments = Set<UserId>()

            for object in itemsToChange {
                let commentFileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: object.fileGroupUUID)
                let userIds = try commentFileModel.userIdsInComments()
                usersMakingComments.formUnion(userIds)
            }

            let fileGroups = itemsToChange.map { $0.fileGroupUUID }
            
            let specifics = MoveItemsSpecifics(usersMakingComments: usersMakingComments, fileGroupsToMove: fileGroups, sourceSharingGroup: sharingGroupUUID, refreshAlbums: { [weak self] in
                guard let self = self else { return }
                self.objects = self.getItemsForAlbum(album: self.sharingGroupUUID)
                self.changeMode = .none
            })
        
            sheetToShow = .moveItemsToAnotherAlbum(specifics)
        } catch let error {
            logger.error("prepareForMove: \(error)")
            showAlert(AlertyHelper.alert(title: "Alert!", message: "There was an error preparing the item move. This can happen if a comment file is missing for an item."))
        }
    }
}
