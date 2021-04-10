
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
    
    let signIns: SignIns
    var observer: AnyObject!
    
    init(signIns: SignIns, serverURL: URL, appGroupIdentifier: String, urlSessionBackgroundIdentifier: String, cloudFolderName: String, db: Connection) throws {
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
        }
    
        let config = Configuration(appGroupIdentifier: appGroupIdentifier, urlSessionBackgroundIdentifier: urlSessionBackgroundIdentifier, serverURL: serverURL, minimumServerVersion: nil, currentClientAppVersion: currentClientAppVersion, failoverMessageURL: nil, cloudFolderName: cloudFolderName, deviceUUID: deviceUUID, temporaryFiles: Configuration.defaultTemporaryFiles)
                
        syncServer = try SyncServer(hashingManager: hashingManager, db: db, requestable: Requestablity(), configuration: config, signIns: signIns, backgroundAsssertable: Background.session.backgroundAsssertable)
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
                showAlert(AlertyHelper.alert(title: "Alert!", message: "There was a server error."))
            }

        case .showAlert(title: let title, message: let message):
            showAlert(AlertyHelper.alert(title: title, message: message))
        }
    }
    
    func syncCompleted(_ syncServer: SyncServer, result: SyncResult) {
        logger.info("syncCompleted: \(result)")
        
        do {
            try syncHelper(result: result)
        } catch let error {
            logger.error("\(String(describing: error))")
            guard AppState.session.current == .foreground else {
                return
            }
            
            showAlert(AlertyHelper.alert(title: "Alert!", message: "There was a server error."))
        }

        guard AppState.session.current == .foreground else {
            return
        }
        
        self.sync.send(result)
    }

    func uuidCollision(_ syncServer: SyncServer, type: UUIDCollisionType, from: UUID, to: UUID) {
    }
    
    // The rest have informative detail; perhaps purely for testing.
    
    func uploadQueue(_ syncServer: SyncServer, event: UploadEvent) {
        logger.info("uploadQueue: \(event)")
    }
    
    func downloadQueue(_ syncServer: SyncServer, event: DownloadEvent) {
        logger.info("downloadQueue: \(event)")
    }
    
    func objectMarkedAsDownloaded(_ syncServer: SyncServer, fileGroupUUID: UUID) {
        guard AppState.session.current == .foreground else {
            return
        }
        
        self.objectMarkedAsDownloaded.send(fileGroupUUID)
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
