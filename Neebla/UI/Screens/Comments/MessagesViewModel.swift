
import Foundation
import MessageKit
import iOSShared
import ChangeResolvers
import iOSBasics
import Combine

class MessagesViewModel: ObservableObject {
    static let maxMessageLength = 1024
    private let commentsFileLabel = FileLabels.comments
    private let object:ServerObjectModel
    private var commentFileModel:ServerFileModel!
    private var commentFileModelURL:URL!
    private var commentFile: CommentFile!

    @Published private(set) var messages: [MessageType]
    private(set) var senderUserId:String!
    private(set) var senderUserDisplayName:String!
    private var listener: AnyCancellable!
    
    init?(object:ServerObjectModel) {
        self.object = object
        messages = []
        
        guard let username = Services.session.signInServices.manager.currentSignIn?.credentials?.username else {
            logger.error("No user name for messages!")
            return nil
        }
        
        senderUserDisplayName = username

        guard let userId = Services.session.userId else {
            logger.error("No user id for messages!")
            return nil
        }
        
        senderUserId = "\(userId)"

        guard loadDiscussion() else {
            logger.error("Could not load discussion!")
            return nil
        }
        
        // So if an object gets downloaded while we're on a screen using this model.
        listener = Services.session.serverInterface.$objectMarkedAsDownloaded.sink { [weak self] downloadedFileGroupUUID in
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
            let initial = String(namePart[namePart.startIndex])
            initials += initial
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
        
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: record)
        } catch let error {
            logger.error("Could not convert record to data: \(error)")
            return false
        }
        
        do {
            // Add using the `WholeFileReplacer` method. Not necessary to add it this way, but I want to simulate what happens on the server-- to avoid issues on the server. Plus, we need the `Data` to queue the upload anyways.
            try commentFile.add(newRecord: data)
        } catch let error {
            logger.error("Could not add record: \(error)")
            return false
        }
        
        // Succeeded in simulated server addition. Now upload the comment.
        do {
            try CommentUploader.queueUpload(fileUUID: commentFileModel.fileUUID, comment: data, object: object)
        } catch let error {
            logger.error("Could not queue the comment for upload: \(error)")
            return false
        }
                
        // Finally, make the new message show up on the UI.
        messages.append(message)

        return true
    }
}
