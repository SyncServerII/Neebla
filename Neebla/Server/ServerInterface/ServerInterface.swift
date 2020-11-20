
import Foundation
import iOSBasics
import iOSShared
import SQLite
import iOSDropbox
import iOSSignIn
import PersistentValue
import ServerShared

enum ServerInterfaceError: Error {
    case cannotFindFile
    case noDeviceUUID
    case badUUID
    case noSharingGroups
    case cannotConvertStringToData
    case noServerURL
}

class ServerInterface {
    var firstSharingGroupUUID:UUID?
    
    // Storing in a file so it's easier to access this from a sharing extension.
    let deviceUUIDString = try! PersistentValue<String>(name: "ServerInterface.deviceUUID", storage: .file)
    
    let deviceUUID:UUID
    
    let hashingManager = HashingManager()
    let syncServer:SyncServer
        
    // Subscribe to this to get sync completions.
    @Published var sync: SyncResult?
    
    // Subscribe to this to get error completions.
    @Published var error: ErrorEvent?
    
    // Subscribe to this to get fileGroupUUID's of objects marked as downloaded.
    @Published var objectMarkedAsDownloaded: UUID?

    init(signIns: SignIns, serverURL: URL, appGroupIdentifier: String, urlSessionBackgroundIdentifier: String) throws {
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

        try hashingManager.add(hashing: DropboxHashing())

        let dbURL = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.syncServerDatabase)
        logger.info("SyncServer SQLite db: \(dbURL.path)")
        let db = try Connection(dbURL.path)

        let config = Configuration(appGroupIdentifier: appGroupIdentifier, urlSessionBackgroundIdentifier: urlSessionBackgroundIdentifier, serverURL: serverURL, minimumServerVersion: nil, failoverMessageURL: nil, cloudFolderName: "BackgroundTesting", deviceUUID: deviceUUID, temporaryFiles: Configuration.defaultTemporaryFiles)

        syncServer = try SyncServer(hashingManager: hashingManager, db: db, configuration: config, signIns: signIns)
        logger.info("SyncServer initialized!")
        
        syncServer.delegate = self
        syncServer.helperDelegate = self
    }
}

extension ServerInterface: SyncServerDelegate {
    func error(_ syncServer: SyncServer, error: ErrorEvent) {
        logger.error("\(String(describing: error))")
        self.error = error
    }
    
    func syncCompleted(_ syncServer: SyncServer, result: SyncResult) {
        logger.info("syncCompleted: \(result)")
        do {
            try syncHelper(result: result)
        } catch let error {
            self.error = .error(error)
        }
        
        self.sync = result
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
        self.objectMarkedAsDownloaded = fileGroupUUID
    }

    // Request to server for upload deletion completed successfully.
    func deletionCompleted(_ syncServer: SyncServer) {
        logger.info("deletionCompleted")
    }

    // Called when vN deferred upload(s), or deferred deletions, successfully completed, is/are detected.
    func deferredCompleted(_ syncServer: SyncServer, operation: DeferredOperation, numberCompleted: Int) {
        logger.info("deferredCompleted: \(operation); numberCompleted: \(numberCompleted)")
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
