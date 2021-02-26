
import Foundation
import iOSBasics
import iOSShared
import SQLite
import iOSSignIn
import PersistentValue
import ServerShared
import Version
import Combine

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
    
    private var syncCompletion:((Error?)->())?

    init(signIns: SignIns, serverURL: URL, appGroupIdentifier: String, urlSessionBackgroundIdentifier: String, cloudFolderName: String) throws {
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

        let dbURL = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.syncServerDatabase)
        logger.info("SyncServer SQLite db: \(dbURL.path)")
        let db = try Connection(dbURL.path)

        // The version in `CFBundleShortVersionString` needs to have format X.Y.Z.
        var currentClientAppVersion: Version?
        if let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            currentClientAppVersion = try? Version(versionString)
        }
    
        let config = Configuration(appGroupIdentifier: appGroupIdentifier, urlSessionBackgroundIdentifier: urlSessionBackgroundIdentifier, serverURL: serverURL, minimumServerVersion: nil, currentClientAppVersion: currentClientAppVersion, failoverMessageURL: nil, cloudFolderName: cloudFolderName, deviceUUID: deviceUUID, temporaryFiles: Configuration.defaultTemporaryFiles)

        syncServer = try SyncServer(hashingManager: hashingManager, db: db, reachability: Reachability(), configuration: config, signIns: signIns)
        logger.info("SyncServer initialized!")
        
        try addHashingForCloudStorageSignIns(hashingManager: hashingManager)
        
        syncServer.delegate = self
        syncServer.helperDelegate = self
    }
    
    private func sync(completion: @escaping (Error?)->()) {
        do {
            syncCompletion = completion
            try syncServer.sync()
        } catch let error {
            logger.error("\(error)")
            syncCompletion = nil
            completion(error)
        }
    }
}

extension ServerInterface: SyncServerDelegate {
    func badVersion(_ syncServer: SyncServer, version: BadVersion) {
        DispatchQueue.main.async {
            switch version {
            case .badServerVersion:
                showAlert(AlertyHelper.alert(title: "Alert!", message: "The server version is bad. This is likely a developer problem. Whoops."))
            case .badClientAppVersion:
                showAlert(AlertyHelper.alert(title: "Alert!", message: "The Neebla app is out of date. You need to update it from the Apple App store."))
            }
        }
    }
    
    func userEvent(_ syncServer: SyncServer, event: UserEvent) {
        switch event {
        case .error(let error):
            logger.error("\(String(describing: error))")
            showAlert(AlertyHelper.alert(title: "Alert!", message: "There was a server error."))

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
            showAlert(AlertyHelper.alert(title: "Alert!", message: "There was a server error."))
        }

        if let syncCompletion = syncCompletion {
            self.syncCompletion = nil
            syncCompletion(nil)
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
        self.objectMarkedAsDownloaded.send(fileGroupUUID)
    }

    // Request to server for upload deletion completed successfully.
    func deletionCompleted(_ syncServer: SyncServer, forObjectWith fileGroupUUID: UUID) {
        logger.info("deletionCompleted")
        self.deletionCompleted.send(fileGroupUUID)
    }

    // Called when vN deferred upload(s), or deferred deletions, successfully completed, is/are detected.
    func deferredCompleted(_ syncServer: SyncServer, operation: DeferredOperation, fileGroupUUIDs: [UUID]) {
        logger.info("deferredCompleted: \(operation); numberCompleted: \(fileGroupUUIDs.count)")
        
        // Dealing with: https://github.com/SyncServerII/Neebla/issues/5
        sync { [weak self] error in
            guard let self = self else { return }

            for fileGroupUUID in fileGroupUUIDs {
                do {
                    try self.triggerDownloadIfNeeded(forFileGroupUUID: fileGroupUUID)
                } catch let error {
                    logger.error("\(error)")
                }
            }
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
