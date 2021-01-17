import UIKit
import iOSSignIn
import iOSShared
import ServerShared
import iOSBasics
import PersistentValue
import SQLite

// These services are shared with the Share Extension

enum ServicesError: Error {
    case noDocumentDirectory
}

class Services {
    // Not really confidential, but it's a key for the server, so storing it in the keychain. Storing as a string because I don't have Int64's in PersistentValue's. :(.
    static let userIdString = try! PersistentValue<String>(name: "Services.userIdString", storage: .keyChain)
    var syncServerUserId: Int64? {
        get {
            if let str = Self.userIdString.value {
                return Int64(str)
            }
            return nil
        }
        
        set {
            if let newValue = newValue {
                Self.userIdString.value = "\(newValue)"
            }
            else {
                Self.userIdString.value = nil
            }
        }
    }
    
    var userId: UserId? {
        get {
            return syncServerUserId
        }
        
        set(newValue) {
            syncServerUserId = newValue
        }
    }
    
    var username: String? {
        return signInServices.manager.currentSignIn?.credentials?.username
    }
    
    // You must use the App Groups Entitlement and setup a applicationGroupIdentifier https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups
    let applicationGroupIdentifier = "group.biz.SpasticMuffin.SharedImages"
    
    let urlSessionBackgroundIdentifier = "biz.SpasticMuffin.SyncServer.Shared"
    
    // See https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    // Note this can't just be your bundle ID. See https://useyourloaf.com/blog/keychain-group-access/
    // and https://stackoverflow.com/questions/11726672/access-app-identifier-prefix-programmatically
    let keychainSharingGroup = "BH68R29JBE.biz.SpasticMuffin.SharedImages"
    
    // Going to use the literal bundle id, so it's the same across the app and the sharing extension.
    let keychainService = "biz.SpasticMuffin.SharedImages"

    // In the documents directory
    let logFileName = "LogFile.txt"

    static private var _session:Services!
        
    // I'm being very careful here because of a problem that's coming up in the sharing extension. If the sharing extension is used twice in a row, we oddly have a state where it's already been initialized. Get a crash on multiple initialization.
    static var session:Services {
        set {
            guard _session == nil else {
                fatalError("You have already called Self.setup!")
            }
            _session = newValue
        }
        get {
            guard let session = _session else {
                fatalError("You have not yet called Self.setup!")
            }
            return session
        }
    }
    
    var syncServer: SyncServer {
        return serverInterface.syncServer
    }
    
    var configuration:UIConfiguration!
    var signInServices: SignInServices!
    var serverInterface:ServerInterface!
    
    var currentSignIns = [GenericSignIn]()
    private static let plistServerConfig = ("Server", "plist")

    enum SetupState: Equatable {
        case none
        case done(appLaunch: Bool)
        case failure
        
        var isComplete: Bool {
            return self == .done(appLaunch: true)
        }
    }
    
    static var setupState: SetupState = .none
    
    // Neebla database
    var db:Connection!
    weak var delegate: ServicesDelegate?

    private init(delegate: ServicesDelegate?) {
        self.delegate = delegate
        
        do {
            try SharedContainer.appLaunchSetup(applicationGroupIdentifier: applicationGroupIdentifier)
        } catch let error {
            logger.error("\(error)")
            Self.setupState = .failure
            return
        }
        
        do {
            try LocalFiles.setup()
        } catch let error {
            logger.error("\(error)")
            Self.setupState = .failure
            return
        }

        do {
            try connectToLocalDatabase()
            try SetupLocalDatabase.setup(db: db)
        } catch let error {
            logger.error("\(error)")
            Self.setupState = .failure
            return
        }
        
        logger.info("SharedContainer.session.sharedContainerURL: \(String(describing: SharedContainer.session?.sharedContainerURL))")
                
        guard let documentsURL = SharedContainer.session?.documentsURL else {
            logger.error("Could not get documentsURL")
            Self.setupState = .failure
            return
        }
        
        PersistentValueFile.alternativeDocumentsDirectory = documentsURL.path
        PersistentValueKeychain.keychainService = keychainService
        PersistentValueKeychain.accessGroup = keychainSharingGroup

        guard let path = Bundle.main.path(forResource: Self.plistServerConfig.0, ofType: Self.plistServerConfig.1) else {
            Self.setupState = .failure
            return
        }
        
        guard let configPlist = ConfigPlist(filePath: path) else {
            Self.setupState = .failure
            return
        }
        
        guard let urlString = configPlist.getValue(for: .serverURL),
            let serverURL = URL(string: urlString) else {
            logger.error("Cannot get server URL")
            Self.setupState = .failure
            return
        }
        
        guard let cloudFolderName = configPlist.getValue(for: .cloudFolderName) else {
            logger.error("Cannot get cloud folder name")
            Self.setupState = .failure
            return
        }
        
        let signIns = SignIns(signInServicesHelper: self)
        signIns.delegate = self
        
        do {
            serverInterface = try ServerInterface(signIns: signIns, serverURL: serverURL, appGroupIdentifier: applicationGroupIdentifier, urlSessionBackgroundIdentifier: urlSessionBackgroundIdentifier, cloudFolderName: cloudFolderName)
        } catch let error {
            logger.error("Could not start ServerInterface: \(error)")
            Self.setupState = .failure
        }
        
        // This is used to form the URL-type links used for sharing.
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            logger.error("Could not get bundle identifier")
            Self.setupState = .failure
            return
        }
        
        do {
            try setupLogging()
        } catch let error {
            logger.error("Could not setup logging: \(error)")
            Self.setupState = .failure
            return
        }
        
        // Do this *after* `setupLogging`-- the initial logger created by `iOSShared` doesn't have the file logging setup.
        set(logLevel: .trace)
        
        setupSignInServices(configPlist: configPlist, signIns: signIns, bundleIdentifier: bundleIdentifier, helper: self)
        
        logger.info("Services: init successful!")
        Self.setupState = .done(appLaunch: false)
    }
    
    // This *must* be called prior to any uses of `session`.
    static func setup(delegate: ServicesDelegate?) {
        session = Services(delegate: delegate)
    }
    
    func appLaunch(options: [UIApplication.LaunchOptionsKey: Any]?) {
        for signIn in currentSignIns {
            do {
                try signInServices.manager.addSignIn(signIn, launchOptions: options)
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        Self.setupState = .done(appLaunch: true)
    }
}

extension Services: SharingInvitationHelper {
    func getSharingInvitationInfo(sharingInvitationUUID: UUID, completion: @escaping (Swift.Result<SharingInvitationInfo, Error>) -> ()) {
        serverInterface.syncServer.getSharingInvitationInfo(sharingInvitationUUID: sharingInvitationUUID, completion: completion)
    }
    
    func sharingInvitationUserAlert(_ sharingInvitation: SharingInvitation, title: String, message: String) {
        serverInterface.userEvent = .showAlert(title: title, message: message)
    }
}
