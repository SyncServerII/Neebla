
import Foundation
import Combine
import iOSShared
import MessageUI
import ServerShared
import SQLite

enum AlbumsScreenActiveSheet: Identifiable {
    case albumSharing
    case email
    
    var id: Int {
        hashValue
    }
}

struct SharingEmailContents {
    let subject: String
    let body: String
}

class AlbumsViewModel: ObservableObject, ModelAlertDisplaying {
    @Published var isShowingRefresh = false
    
    @Published var activeSheet:AlbumsScreenActiveSheet?
    @Published var sharingMode = false
    @Published var albumToShare: AlbumModel?
    @Published var canSendMail: Bool = MFMailComposeViewController.canSendMail()
    @Published var sendMailResult: Swift.Result<MFMailComposeResult, Error>? = nil
    @Published var emailMessage: SharingEmailContents?

    @Published var albums = [AlbumModel]()
        
    @Published var presentTextInput = false
    @Published var textInputAlbumName: String?
    @Published var textInputInitialAlbumName: String?
    @Published var textInputPriorAlbumName: String?
    @Published var textInputActionButtonName: String?
    @Published var textInputNewAlbum: Bool = false
    @Published var textInputTitle: String?
    var textInputAction: (()->())?
    
    private var syncSubscription:AnyCancellable!
    var userEventSubscription:AnyCancellable!
    let userAlertModel:UserAlertModel
    
    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleUserEvents()
        
        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            
            self.isShowingRefresh = false
            self.getCurrentAlbums()
        }
        
        getCurrentAlbums()
    }

    func getCurrentAlbums() {
        if let albums = try? AlbumModel.fetch(db: Services.session.db, where: AlbumModel.deletedField.description == false) {
            self.albums = albums.sorted(by: { (a1, a2) -> Bool in
                let name1 = a1.albumName ?? AlbumModel.untitledAlbumName
                let name2 = a2.albumName ?? AlbumModel.untitledAlbumName
                return name1 < name2
            })
        }
        else {
            self.albums = []
        }
    }
    
    private func createNewAlbum(newAlbumName: String?) {
        let newSharingGroupUUID = UUID()
        
        Services.session.serverInterface.syncServer.createSharingGroup(sharingGroupUUID: newSharingGroupUUID, sharingGroupName: newAlbumName) { [weak self] error in
            guard let self = self else { return }

            guard error == nil else {
                self.userAlertModel.userAlert = .error(message: "Failed to create album.")
                return
            }
            
            // Don't do a sync-- `createSharingGroup` does it for us and if we do another it seems we can get an error due to a race condition.
        }
    }
    
    private func changeAlbumName(sharingGroupUUID: UUID, changedAlbumName: String?) {
        var changedAlbumName = changedAlbumName
        if changedAlbumName == "" {
            // So we get default title
            changedAlbumName = nil
        }
        
        Services.session.serverInterface.syncServer.updateSharingGroup(sharingGroupUUID: sharingGroupUUID, newSharingGroupName: changedAlbumName) { error in
            guard error == nil else {
                self.userAlertModel.userAlert = .error(message: "Failed to change album name.")
                return
            }
            
            // No need to do a `sync`. `updateSharingGroup` does one when successful.
        }
    }
    
    func sync() {
        do {
            try Services.session.syncServer.sync()
        } catch let error {
            logger.error("\(error)")
            isShowingRefresh = false
            userAlertModel.userAlert = .error(message: "Failed to sync.")
        }
    }
    
    func startChangeExistingAlbumName(sharingGroupUUID: UUID, currentAlbumName: String?) {
        textInputTitle = "Change Album Name:"
        textInputActionButtonName = "Change"
        
        textInputAction = { [weak self] in
            guard let self = self else { return }
            let changedAlbumName = self.textInputAlbumName ?? AlbumModel.untitledAlbumName
            self.changeAlbumName(sharingGroupUUID: sharingGroupUUID, changedAlbumName: changedAlbumName)
        }
        
        textInputInitialAlbumName = currentAlbumName ?? AlbumModel.untitledAlbumName
        textInputAlbumName = nil
        textInputPriorAlbumName = currentAlbumName
        textInputNewAlbum = false
        presentTextInput = true
    }
    
    func startCreateNewAlbum() {
        textInputTitle = "New Album Name:"
        textInputActionButtonName = "Create"

        textInputAction = { [weak self] in
            guard let self = self else { return }
            let newAlbumName = self.textInputAlbumName ?? AlbumModel.untitledAlbumName
            self.createNewAlbum(newAlbumName: newAlbumName)
        }
        
        textInputInitialAlbumName = AlbumModel.untitledAlbumName
        textInputAlbumName = nil
        textInputNewAlbum = true
        presentTextInput = true
    }
    
    private func createSharingInvitationLink(invitationCode: UUID) -> String {
        return Services.session.signInServices.sharingInvitation.createSharingURL(invitationCode: invitationCode.uuidString)
    }
    
    func emailContents(from parameters: AlbumSharingParameters) -> SharingEmailContents {
        let sharingURLString = createSharingInvitationLink(invitationCode: parameters.invitationCode)
        
        var socialText = " "
        if parameters.allowSocialAcceptance {
            socialText = ", Facebook, "
        }
    
        var albumName = "a media album"
        var subjectAlbumName = ""
        if let sharingGroupName = parameters.sharingGroupName {
            albumName = "the media album '\(sharingGroupName)'"
            subjectAlbumName = "\(sharingGroupName) "
        }
    
        let message = """
            I'd like to share \(albumName) with you through the Neebla app and your Dropbox\(socialText)or Google account. To share media, you need to:
            
            1) Download the Neebla iOS app onto your iPhone or iPad,
            2) Tap the link below in the Apple Mail app, and
            3) Follow the instructions within the app to sign in to your Dropbox\(socialText)or Google account.
            You will have \(parameters.permission.displayableText) access to media.

                \(sharingURLString)

            If you can't tap the link above, then you can copy the sharing code below:

            \t\(parameters.invitationCode.uuidString)

            and paste it into the 'Album Sharing' screen of the Neebla app.
        """
        
        let subject = "Share \(subjectAlbumName)media using the Neebla app"
        
        return SharingEmailContents(subject: subject, body: message)
    }
}
