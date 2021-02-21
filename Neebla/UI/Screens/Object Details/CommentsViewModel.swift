
import Foundation
import MessageKit
import iOSShared
import ChangeResolvers
import iOSBasics
import Combine

class CommentsViewModel: ObservableObject {
    static let maxMessageLength = 1024
    private let commentsFileLabel = FileLabels.comments
    private let object:ServerObjectModel
    private var commentFileModel:ServerFileModel!
    private var commentFileModelURL:URL!
    private var commentFile: CommentFile!
    
    private(set) var allowingSending = true

    let unknownUserInitials = "MT"
    let unknownUserID = -1

    @Published private(set) var messages: [MessageType]

    private(set) var senderUserId:String!
    private(set) var senderUserDisplayName:String!
    private var listener: AnyCancellable!
    
    init?(object:ServerObjectModel) {
        self.object = object
        messages = []
        
        // If the user is signed in, allow user to view and send messages.
        // If the user is *not* signed in, allow user to view but not send messages.

        if !Services.session.userIsSignedIn {
            allowingSending = false
        }
        
        // Prioritizing the local setting-- but plan to propagate this local setting to the server in a new API call.
        if let username = try? SettingsModel.userName(db: Services.session.db) {
            senderUserDisplayName = username
        }
        else if let username = Services.session.signInServices.manager.currentSignIn?.credentials?.username {
            senderUserDisplayName = username
        }
        else {
            logger.warning("No user name for messages")
            senderUserDisplayName = unknownUserInitials
            allowingSending = false
        }

        if let userId = Services.session.userId {
            senderUserId = "\(userId)"
        }
        else {
            logger.warning("No user id for messages!")
            senderUserId = "\(unknownUserID)"
            allowingSending = false
        }
        
        guard loadDiscussion() else {
            logger.error("Could not load discussion!")
            return nil
        }
        
        // So if an object gets downloaded while we're on a screen using this model.
        listener = Services.session.serverInterface.objectMarkedAsDownloaded.sink { [weak self] downloadedFileGroupUUID in
            guard let self = self else { return }
            
            guard downloadedFileGroupUUID == object.fileGroupUUID else {
                return
            }
            
            // Load the discussion again, with any changes.
            guard self.loadDiscussion() else {
                logger.error("Could not load discussion!")
                return
            }
        }
    }
    
    private func loadDiscussion() -> Bool {
        do {
            commentFileModel = try ServerFileModel.getFileFor(fileLabel: commentsFileLabel, withFileGroupUUID: object.fileGroupUUID)
        } catch let error {
            logger.error("Problem loading messages: Could not get file model: \(error)")
            return false
        }
        
        commentFileModelURL = commentFileModel.url
        
        guard let _ = commentFileModelURL else {
            logger.error("Problem loading messages: The discussion had no URL!")
            return false
        }
        
        do {
            commentFile = try CommentFile(with: commentFileModelURL)
        } catch let error {
            logger.error("Problem loading messages: \(error)")
            return false
        }
        
        messages = []
        
        for fixedObject in commentFile {
            guard let dict = fixedObject as? [String: String],
                let message = DiscussionMessage.fromDictionary(dict) else {
                logger.error("Problem loading messages: Has there been a format change?")
                return false
            }
            
            messages += [message]
        }
        
        logger.info("Loaded \(messages.count) messages")
        
        return true
    }
    
    func getInitialsFromSenderDisplayName(sender: SenderType) -> String {
        var initials = ""
        let usernameComponents = sender.displayName.components(separatedBy: " ")
        for namePart in usernameComponents {
            guard namePart.count > 0 else {
                continue
            }
            
            let initial = String(namePart[namePart.startIndex])
            initials += initial
        }
        
        if initials.count == 0 {
            return unknownUserInitials
        }
        
        return initials
    }
    
    func addNewMessage(_ message: DiscussionMessage) -> Bool {
        guard let _ = commentFile else {
            return false
        }

        guard let record:CommentFile.FixedObject = message.toDictionary() else {
            return false
        }

        do {
            try addNewMessageHelper(record: record)
        } catch let error {
            logger.error("\(error)")
            return false
        }
        
        // Finally, make the new message show up on the UI.
        messages.append(message)

        return true
    }
    
    private func addNewMessageHelper(record:CommentFile.FixedObject) throws {
        let data = try JSONSerialization.data(withJSONObject: record)

        // Add using the `WholeFileReplacer` method. Not necessary to add it this way, but I want to simulate what happens on the server-- to avoid issues on the server. Plus, we need the `Data` to queue the upload anyways.
        try commentFile.add(newRecord: data)

        // Succeeded in simulated server addition. Now upload the comment.
        try Comments.queueUpload(fileUUID: commentFileModel.fileUUID, comment: data, object: object)

        // Also going to update local file. This file will get replaced in a download from the server next time downloads happen for this object, but without this update we won't have the new comment in the file locally until that download.
        try Comments.save(commentFile: commentFile, commentFileModel: commentFileModel)
    }
    
    func resetUnreadCount() {
        do {
            try Comments.resetReadCounts(commentFileModel: commentFileModel)
        } catch let error {
            logger.error("\(error)")
        }
    }
}
