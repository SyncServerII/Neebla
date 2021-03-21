
import Foundation
import Combine
import iOSShared
import MessageUI
import ServerShared
import SQLite

enum AlbumsScreenActiveSheet: Identifiable {
    case albumSharing
    case email
    case textInput
    
    var id: Int {
        hashValue
    }
}

class AlbumsViewModel: ObservableObject {
    var firstAppearance = true
    @Published var isShowingRefresh = false
    
    @Published var activeSheet:AlbumsScreenActiveSheet?
    @Published var sharingMode = false
    @Published var albumToShare: AlbumModel?
    @Published var canSendMail: Bool = MFMailComposeViewController.canSendMail()
    @Published var sendMailResult: Swift.Result<MFMailComposeResult, Error>? = nil
    @Published var emailMessage: EmailContents?

    @Published var albums = [AlbumModel]()
        
    @Published var textInputAlbumName: String?
    @Published var textInputInitialAlbumName: String?
    @Published var textInputPriorAlbumName: String?
    @Published var textInputActionButtonName: String?
    @Published var textInputNewAlbum: Bool = false
    @Published var textInputTitle: String?
    var textInputAction: (()->())?
    var textInputActionEnabled: (()->(Bool))?
    var textInputKeyPressed:((String?)->())?
    
    private var syncSubscription:AnyCancellable!
    var userEventSubscriptionOther:AnyCancellable!
    var textInputSubscription:AnyCancellable!
    
    var boundedCancel:BoundedCancel?
    
    init() {
        textInputSubscription = $textInputAlbumName.sink { [weak self] text in
            self?.textInputKeyPressed?(text)
        }
        
        syncSubscription = Services.session.serverInterface.sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            
            guard case .noIndex = syncResult else {
                return
            }
            
            self.boundedCancel?.minimumCancel()
            
            self.updateIfNeeded(self.getCurrentAlbums())
        }
        
        userEventSubscriptionOther = Services.session.userEvents.alerty.sink { [weak self] _ in
            guard let self = self else { return }

            if self.isShowingRefresh {
                self.isShowingRefresh = false
            }
        }
        
        // Give the user the current albums to look at initially. There's a `sync` in `onAppear` in the view-- which will update this if needed.
        updateIfNeeded(getCurrentAlbums())
    }
    
    private func updateIfNeeded(_ update: [AlbumModel]) {
        let current = Set<AlbumModel>(albums)
        let new = Set<AlbumModel>(update)
        if current == new {
            // No update needed.
            return
        }
                
        self.albums = update
    }

    func getCurrentAlbums() -> [AlbumModel] {
        if let albums = try? AlbumModel.fetch(db: Services.session.db, where: AlbumModel.deletedField.description == false) {
            return albums.sorted(by: { (a1, a2) -> Bool in
                let name1 = a1.albumName ?? AlbumModel.untitledAlbumName
                let name2 = a2.albumName ?? AlbumModel.untitledAlbumName
                return name1 < name2
            })
        }
        else {
            return []
        }
    }
    
    private func createNewAlbum(newAlbumName: String?) {
        let newSharingGroupUUID = UUID()
        
        Services.session.syncServer.createSharingGroup(sharingGroupUUID: newSharingGroupUUID, sharingGroupName: newAlbumName) { error in
        
            if let noNetwork = error as? Errors, noNetwork.networkIsNotReachable {
                showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                return
            }
                
            guard error == nil else {
                showAlert(AlertyHelper.error(message: "Failed to create album."))
                return
            }
            
            // Don't do a sync-- `createSharingGroup` does it for us and if we do another it seems we can get an error due to a race condition.
        }
    }
    
    // SyncServer doesn't let you change an album name back to nil.
    private func changeAlbumName(sharingGroupUUID: UUID, changedAlbumName: String) {
        Services.session.syncServer.updateSharingGroup(sharingGroupUUID: sharingGroupUUID, newSharingGroupName: changedAlbumName) { error in
        
            if let noNetwork = error as? Errors, noNetwork.networkIsNotReachable {
                showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                return
            }
            
            guard error == nil else {
                showAlert(AlertyHelper.error(message: "Failed to change album name."))
                return
            }
            
            // No need to do a `sync`. `updateSharingGroup` does one when successful.
        }
    }
    
    func startChangeExistingAlbumName(sharingGroupUUID: UUID, currentAlbumName: String?) {
        textInputTitle = "Change Album Name"
        textInputActionButtonName = "Change"
        
        var enabled = false
        if let count = currentAlbumName?.count, count > 0 {
            enabled = true
        }
        
        textInputKeyPressed = { text in
            if let trimmed = text?.trimmingCharacters(in: .whitespaces) {
                if trimmed.count > 0 {
                    enabled = true
                    return
                }
            }
            
            enabled = false
        }
        
        textInputActionEnabled = {
            return enabled
        }
        
        textInputAction = { [weak self] in
            guard let self = self else { return }
            let updatedAlbumName: String
            
            let trimmed = self.textInputAlbumName?.trimmingCharacters(in: .whitespaces)
            
            if let trimmed = trimmed, trimmed.count > 0 {
                updatedAlbumName = trimmed
            }
            else {
                self.textInputAlbumName = trimmed
                return
            }

            self.changeAlbumName(sharingGroupUUID: sharingGroupUUID, changedAlbumName: updatedAlbumName)
        }

        textInputInitialAlbumName = currentAlbumName ?? AlbumModel.untitledAlbumName

        // If there was a nil album name, just use untitled place holder.
        // But, if there was an album name, I don't want the user to be forced to re-enter the entire name. Perhaps they just want to change it slightly.
        if currentAlbumName == nil {
            textInputAlbumName = nil
        }
        else {
            textInputAlbumName = currentAlbumName
        }
        
        textInputPriorAlbumName = currentAlbumName
        textInputNewAlbum = false
        activeSheet = .textInput
    }
    
    func startCreateNewAlbum() {
        textInputTitle = "New Album Name"
        textInputActionButtonName = "Create"
        
        textInputKeyPressed = nil
        
        // Going to allow nil new album names.
        textInputActionEnabled = nil
        
        textInputAction = { [weak self] in
            guard let self = self else { return }
            
            // But I see no reason to allow white space before/after the album name
            let newAlbumName = self.textInputAlbumName?.trimmingCharacters(in: .whitespaces)
            self.createNewAlbum(newAlbumName: newAlbumName)
        }
        
        textInputInitialAlbumName = AlbumModel.untitledAlbumName
        textInputAlbumName = nil
        textInputNewAlbum = true
        activeSheet = .textInput
    }
    
    private func createSharingInvitationLink(invitationCode: UUID) -> String {
        return Services.session.signInServices.sharingInvitation.createSharingURL(invitationCode: invitationCode.uuidString)
    }
    
    func emailContents(from parameters: AlbumSharingParameters) -> EmailContents {
        let sharingURLString = createSharingInvitationLink(invitationCode: parameters.invitationCode)
    
        var albumName = "a media album"
        var subjectAlbumName = ""
        if let sharingGroupName = parameters.sharingGroupName {
            albumName = "the media album '\(sharingGroupName)'"
            subjectAlbumName = "\(sharingGroupName) "
        }
    
        let accountPhrase = Services.session.emailPhraseForSharing(allowSocialAcceptance: parameters.allowSocialAcceptance)
        
        let message = """
            I'd like to share \(albumName) with you through the Neebla app and your \(accountPhrase) account.
            
            To share media, you need to:
            
            1) Download the Neebla iOS app onto your iPhone or iPad:
                \(AppStore.neeblaAppStoreLink)
                
            2) Tap the link below in the Apple Mail app:
            
                \(sharingURLString)
                
            3) Then, follow the instructions within the app to sign in to your \(accountPhrase) account.
            
            You will have \(parameters.permission.displayableText) access to media.

            If you can't tap the link above, then you can copy the sharing code below:

            \t\(parameters.invitationCode.uuidString)

            and paste it into the 'Album Sharing' screen of the Neebla app.
        """
        
        let subject = "Share \(subjectAlbumName)media using the Neebla app"
        
        return EmailContents(subject: subject, body: message)
    }
    
    func checkForNotificationAuthorization() {
        // Not much point in doing this if user isn't signed in. This may require server communication. And notifications themselves only make sense if a user is signed in.
        guard Services.session.userIsSignedIn else {
            logger.warning("checkForNotificationAuthorization: Not doing. User is not signed in.")
            return
        }
        
        PushNotifications.session.checkForNotificationAuthorization()
    }
    
    static func getAlbum(sharingGroupUUID: UUID) throws -> AlbumModel? {
        return try AlbumModel.fetchSingleRow(db: Services.session.db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroupUUID)
    }
}
