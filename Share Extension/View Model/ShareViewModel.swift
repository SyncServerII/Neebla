//
//  ShareViewModel.swift
//  Share Extension
//
//  Created by Christopher G Prince on 11/15/20.
//

import Foundation
import iOSShared
import Combine
import CoreGraphics

class ShareViewModel: ObservableObject {
    @Published var width: CGFloat = 0
    @Published var height: CGFloat = 0
    @Published var sharingGroups = [SharingGroupData]()
    @Published var selectedSharingGroupUUID: UUID?
    @Published var sharingItem: SXItemProvider?
    
    var userEventSubscription: AnyCancellable!
    var userIsSignedInSubscription: AnyCancellable!
    var cancel:(()->())?
    private var syncSubscription:AnyCancellable!
    private var initialSync = false
    
    // Make sure `Services.session` is setup before calling this.
    func setupAfterServicesInitialized() {
        // Have to do some wrangling to get an initial sync because user sign in may be async.
        userIsSignedInSubscription = Services.session.signInServices.manager.$userIsSignedIn.sink { [weak self] signedIn in
            guard let self = self else { return }
            if let signedIn = signedIn, signedIn {
                logger.debug("userIsSignedInSubscription: about to do sync")
                self.sync()
            }
            self.userIsSignedInSubscription = nil
        }

        syncSubscription = Services.session.serverInterface.sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            logger.debug("syncSubscription: sync completed")
            self.syncCompletionHelper()
        }
    }
    
    // This was failing with a lack of a network connection until I changed the default on network reachability to `true`. See https://github.com/rwbutler/Hyperconnectivity/issues/1
    func sync() {
        do {
            try Services.session.syncServer.sync()
        }
        catch let error {
            logger.error("\(error)")
            
            if let networkError = error as? Errors, networkError.networkIsNotReachable {
                showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                return
            }
        }
    }
    
    private func syncCompletionHelper() {
        if let sharingGroups = try? Services.session.syncServer.sharingGroups() {
            let sharingGroups = sharingGroups.sorted { (s1, s2) -> Bool in
                let name1 = s1.sharingGroupName ?? AlbumModel.untitledAlbumName
                let name2 = s2.sharingGroupName ?? AlbumModel.untitledAlbumName
                return name1 < name2
            }
            self.sharingGroups = sharingGroups.enumerated().map { index, group in
                return SharingGroupData(id: group.sharingGroupUUID, name: group.sharingGroupName ?? "Album \(index)")
            }
        }
    }
    
    func upload(item: SXItemProvider, sharingGroupUUID: UUID) {
        do {
            try item.upload(toAlbum: sharingGroupUUID)
            
            // Once the upload is triggered, close the sharing extension. The upload will continue in the background! :)
            cancel?()
        } catch let error {
            logger.error("\(error)")
        }
    }
}
