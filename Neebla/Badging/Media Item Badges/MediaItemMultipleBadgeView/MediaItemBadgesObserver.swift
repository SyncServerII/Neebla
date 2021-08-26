//
//  MediaItemBadgesObserver.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/18/21.
//

import Foundation
import iOSShared
import ChangeResolvers

struct Badges {
    struct UserBadge {
        let userId: String
        let badge: MediaItemBadge
    }
    
    let selfBadge: MediaItemBadge?
    let othersBadges: [UserBadge]
}

protocol MediaItemBadgesObserverDelegate: AnyObject {
    var mediaItemBadges: Badges? { get set }
}

class MediaItemBadgesObserver {
    enum MediaItemBadgesObserverError: Error {
        case noBadgeForUserId
    }
    
    let object: ServerObjectModel
    private var observer: AnyObject?
    private var mediaItemAttributesFileUUID: UUID!
    weak var delegate: MediaItemBadgesObserverDelegate!
    let maxNumberOthersBadges: Int
    
    init(object: ServerObjectModel, delegate: MediaItemBadgesObserverDelegate, maxNumberOthersBadges: Int) {
        self.object = object
        self.delegate = delegate
        self.maxNumberOthersBadges = maxNumberOthersBadges
        
        do {
            let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
            mediaItemAttributesFileUUID = fileModel.fileUUID
            delegate.mediaItemBadges = try getBadges(mediaItemAttributesFileModel: fileModel)
        }
        catch let error {
            // 6/21/21; Only logging these as `.debug` because there are many `noFileForFileLabel` errors thrown at this stage in adding the media item badges, and `.error` logging clogs up the logs.
            logger.debug("\(error)")
            return
        }
        
        observer = NotificationCenter.default.addObserver(forName: ServerFileModel.badgeUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let (fileUUID, _) = ServerFileModel.getUUIDs(from: notification), self.mediaItemAttributesFileUUID == fileUUID else {
                return
            }
            
            do {
                let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
                let badges = try self.getBadges(mediaItemAttributesFileModel: fileModel)
                self.updateBadge(badges)
            } catch let error {
                logger.error("\(error)")
            }
        }
    }
    
    private func getBadges(mediaItemAttributesFileModel: ServerFileModel) throws -> Badges? {
        guard let url = mediaItemAttributesFileModel.url else {
            logger.debug("No URL in mediaItemAttributesFileModel")
            return nil
        }

        let data = try Data(contentsOf: url)
        let mia = try MediaItemAttributes(with: data)
        
        var userIds = mia.badgeUserIdKeys()
                
        guard let selfUserId = Services.session.userId else {
            logger.debug("No userId")
            return nil
        }
        
        let selfUserIdString = "\(selfUserId)"
        var selfBadge:MediaItemBadge?
        
        // Want the self badge separately if we have it. The file model will have the most up to date value for self; using the file model is much faster in terms of getting changed values for self-badge to the UI.
        if let badge = mediaItemAttributesFileModel.badge {
            selfBadge = badge
            userIds.remove(selfUserIdString)
        }
        
        assert(!userIds.contains(selfUserIdString))
        
        // Sort the others userId's so we show their badges in a standard order.
        var sortedOtherUserIds = userIds.sorted()
        sortedOtherUserIds.removeLast(
            max(sortedOtherUserIds.count - maxNumberOthersBadges, 0))

        var othersBadges = [Badges.UserBadge]()
        
        for otherUserId in sortedOtherUserIds {
            let otherUserBadge = try getBadge(for: otherUserId, mia: mia)
            if otherUserBadge == .none {
                continue
            }
            
            logger.debug("otherUserId: \(otherUserId); badge: \(otherUserBadge)")

            let userBadge = Badges.UserBadge(userId: otherUserId, badge: otherUserBadge)
            othersBadges += [userBadge]
        }
        
        return Badges(selfBadge: selfBadge, othersBadges: othersBadges)
    }
    
    func getBadge(for userId: String, mia: MediaItemAttributes) throws -> MediaItemBadge {
        let badge = mia.get(type: .badge, key: "\(userId)")
        switch badge {
        case .badge(userId: _, code: let badgeCode):
            if let badgeCode = badgeCode,
                let mediaItemBadge = MediaItemBadge(rawValue: badgeCode) {
                return mediaItemBadge
            }
            logger.error("Could not get badge for known userId from media item attributes file")
            
        default:
            logger.error("Could not get badge from media item attributes file")
        }
        
        throw MediaItemBadgesObserverError.noBadgeForUserId
    }
    
    private func updateBadge(_ badges: Badges?) {
        // Because `badgeUpdate` gets posted in some cases from a non-main thread.
        DispatchQueue.main.async {
            self.delegate?.mediaItemBadges = badges
        }
    }
}
