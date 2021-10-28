
import Foundation
import iOSBasics
import iOSShared
import SQLite
import iOSSignIn
import PersistentValue
import ServerShared
import Version
import Combine
import SQLiteObjc

enum ServerInterfaceError: Error {
    case cannotFindFile
    case noDeviceUUID
    case badUUID
    case noSharingGroups
    case cannotConvertStringToData
    case noServerURL
}

class ServerInterface {    
    // Storing in a file so it's easier to access this from a sharing extension.
    let deviceUUIDString = try! PersistentValue<String>(name: "ServerInterface.deviceUUID", storage: .file)
    
    let deviceUUID:UUID
    
    let hashingManager = HashingManager()
    let syncServer:SyncServer
        
    // Subscribe to this to get sync completions.
    let sync = PassthroughSubject<SyncResult?, Never>()
    
    // Subscribe to this to get fileGroupUUID's of objects marked as downloaded.
    let objectMarkedAsDownloaded = PassthroughSubject<UUID?, Never>()
    
    // Subscribe to this to get fileGroupUUID's of objects deleted.
    let deletionCompleted = PassthroughSubject<UUID?, Never>()

    // Subscribe to these to get events about uploads/downloads.
    let uploadQueue = PassthroughSubject<UploadEvent, Never>()
    let downloadQueue = PassthroughSubject<DownloadEvent, Never>()
    
    let signIns: SignIns
    var observer: AnyObject!
    
    let config:Configuration
    
    // currentUserId is for some specific fixes in iOSBasics.
    init(signIns: SignIns, serverURL: URL, appGroupIdentifier: String, urlSessionBackgroundIdentifier: String, cloudFolderName: String, failoverMessageURL: URL, currentUserId: UserId?, db: Connection) throws {
        self.signIns = signIns

        if deviceUUIDString.value == nil {
            let uuid = UUID().uuidString
            deviceUUIDString.value = uuid
            logger.info("Created new deviceUUID: \(uuid)")
        }
        else {
            logger.info("Using existing deviceUUID")
        }
        
        guard let uuidString = deviceUUIDString.value else {
            throw ServerInterfaceError.noDeviceUUID
        }
        
        guard let uuid = UUID(uuidString: uuidString) else {
            throw ServerInterfaceError.badUUID
        }
        
        deviceUUID = uuid
        
        // The version in `CFBundleShortVersionString` needs to have format X.Y.Z.
        var currentClientAppVersion: Version?
        if let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            currentClientAppVersion = try? Version(versionString)
            if currentClientAppVersion == nil {
                logger.error("Could not get currentClientAppVersion: App version string: \(versionString)")
            }
        }

        let minimumServerVersion = Version("1.9.0")
    
        config = Configuration(appGroupIdentifier: appGroupIdentifier, urlSessionBackgroundIdentifier: urlSessionBackgroundIdentifier, serverURL: serverURL, minimumServerVersion: minimumServerVersion, currentClientAppVersion: currentClientAppVersion, failoverMessageURL: failoverMessageURL, cloudFolderName: cloudFolderName, deviceUUID: deviceUUID, temporaryFiles: Configuration.defaultTemporaryFiles, allowUploadDownload: true)
                
        syncServer = try SyncServer(hashingManager: hashingManager, db: db, requestable: Requestablity(), configuration: config, signIns: signIns, backgroundAsssertable: Background.session.backgroundAsssertable, currentUserId: currentUserId)
        logger.info("SyncServer initialized!")
        
        try addHashingForCloudStorageSignIns(hashingManager: hashingManager)
        
        syncServer.delegate = self
        syncServer.helperDelegate = self
        
        observer = NotificationCenter.default.addObserver(forName: AppState.update, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let state = AppState.getUpdate(from: notification) else {
                logger.error("Cannot get AppState")
                return
            }
            
            do {
                try self.syncServer.appChangesState(to: state)
            } catch let error {
                logger.error("Failed calling appChangesState: \(error)")
            }
        }
    }
}

extension ServerInterface: SyncServerDelegate {
    func badVersion(_ syncServer: SyncServer, version: BadVersion) {
        guard AppState.session.current == .foreground else {
            return
        }
        
        DispatchQueue.main.async {
            switch version {
            case .badServerVersion:
                showAlert(AlertyHelper.alert(title: "Alert!", message: "The server version is bad. This is likely a developer problem. Whoops."))
            case .badClientAppVersion:
                showAlert(AlertyHelper.alert(title: "Alert!", message: "The Neebla app is out of date. Please update it from the Apple App store."))
            }
        }
    }
    
    func userEvent(_ syncServer: SyncServer, event: UserEvent) {
        guard AppState.session.current == .foreground else {
            return
        }
        
        switch event {
        case .error(let error):
            logger.error("\(String(describing: error))")

            if let error = error as? UserDisplayable,
                let message = error.userDisplayableMessage {
                showAlert(AlertyHelper.alert(title: message.title, message: message.message))
            }
            else {
#if DEBUG
                showAlert(AlertyHelper.alert(title: "Alert!", message: "There was a server error: \(String(describing: error))"))
#endif
            }
            // TODO: Have more errors conform to UserDisplable: https://github.com/SyncServerII/Neebla/issues/13

        case .showAlert(title: let title, message: let message):
            showAlert(AlertyHelper.alert(title: title, message: message))
        }
    }
    
    func syncCompleted(_ syncServer: SyncServer, result: SyncResult) {
        do {
            try syncHelper(result: result)
        } catch let error {
            logger.error("\(String(describing: error))")

#if DEBUG
            showAlert(AlertyHelper.alert(title: "Alert!", message: "There was a server error: \(error)"))
#endif
            // TODO: Have errors conform to UserDisplable: https://github.com/SyncServerII/Neebla/issues/13
            
            // Not much point in reporting sync completed since we got an error. Just return.
            return
        }
        
        logger.info("syncCompleted: \(result)")

        guard AppState.session.current == .foreground else {
            return
        }
        
        self.sync.send(result)
    }

    func uuidCollision(_ syncServer: SyncServer, type: UUIDCollisionType, from: UUID, to: UUID) {
        // This is dealing with the media attributes file. It's probably happening due to a race condition with adding a media attributes file on demand. See https://github.com/SyncServerII/Neebla/issues/16
        
        guard type == .file else {
            logger.error("uuidCollision: Could not have type .file: from: \(from) to: \(to)")
            return
        }
        
        do {
            guard let fileModel = try ServerFileModel.fetchSingleRow(db: Services.session.db, where: ServerFileModel.fileUUIDField.description == from) else {
                logger.error("uuidCollision: Could not find `from` uuid: \(from)")
                return
            }
            
            let shouldNotBePresent = try ServerFileModel.fetchSingleRow(db: Services.session.db, where: ServerFileModel.fileUUIDField.description == to)
            guard shouldNotBePresent == nil else {
                logger.error("uuidCollision: Found `to` uuid: \(to)")
                return
            }
            
            try fileModel.update(setters: ServerFileModel.fileUUIDField.description <- to)
            logger.debug("uuidCollision: Success: Updating \(from) to \(to)")
        } catch let error {
            logger.error("uuidCollision: Failed: \(error)")
        }
    }
    
    // The rest have informative detail; perhaps purely for testing.
    
    func uploadQueue(_ syncServer: SyncServer, event: UploadEvent) {
        logger.info("uploadQueue: \(event)")
        uploadQueue.send(event)
    }
    
    func downloadQueue(_ syncServer: SyncServer, event: DownloadEvent) {
        logger.info("downloadQueue: \(event)")
        downloadQueue.send(event)
    }
    
    func objectMarked(_ syncServer: SyncServer, withDownloadState state: DownloadState, fileGroupUUID: UUID) {
        guard AppState.session.current == .foreground else {
            return
        }
        
        switch state {
        case .downloaded:
            self.objectMarkedAsDownloaded.send(fileGroupUUID)

        case .notDownloaded:
            logger.info("Object marked as not downloaded: file group: \(fileGroupUUID)")
        }
    }

    // Request to server for upload deletion completed successfully.
    func deletionCompleted(_ syncServer: SyncServer, forObjectWith fileGroupUUID: UUID) {
        logger.info("deletionCompleted")
        guard AppState.session.current == .foreground else {
            return
        }
        
        self.deletionCompleted.send(fileGroupUUID)
    }

    // Called when vN deferred upload(s), or deferred deletions, successfully completed, is/are detected.
    func deferredCompleted(_ syncServer: SyncServer, operation: DeferredOperation, fileGroupUUIDs: [UUID]) {
        logger.info("deferredCompleted: \(operation); numberCompleted: \(fileGroupUUIDs.count)")

        // Dealing with: https://github.com/SyncServerII/Neebla/issues/5
        // The need here is: The user mutated a (comment) file. We want to download that change.
        // We have to be specific about the sharing group. Assuming for the moment that all the file groups are in the same sharing group (album).
        // NOTE: This doesn't have to be true. If a user added a comment in one album then quickly added a comment in another album this assumption would be incorrect.
        
        guard fileGroupUUIDs.count > 0 else {
            logger.error("Not at least one file group in deferredCompleted")
            return
        }
        
        do {
            let album = try ServerObjectModel.albumFor(fileGroupUUID: fileGroupUUIDs[0], db: Services.session.db)
            try syncServer.sync(sharingGroupUUID: album.sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    // Another client deleted a file/file group.
    func downloadDeletion(_ syncServer: SyncServer, details: DownloadDeletion) {
        logger.info("downloadDeletion: \(details)")
    }
}

extension ServerInterface: SyncServerHelpers {
    func objectType(_ caller: AnyObject, forAppMetaData appMetaData: String) -> String? {
        return nil
    }
}
