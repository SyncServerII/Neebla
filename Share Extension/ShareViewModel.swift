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
    @Published var userSignedIn: Bool = true
    @Published var selectedSharingGroupUUID: UUID?
    @Published var sharingItem: ItemProvider?
    var cancel:(()->())?
    var post:((ItemProvider, _ sharingGroupUUID: UUID)->())!
    
    private var syncSubscription:AnyCancellable!

    init() {
        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            self.syncCompletionHelper()
        }
    }
    
    func sync() {
        do {
            try Services.session.syncServer.sync()
        }
        catch let error {
            logger.error("\(error)")
        }
    }
    
    private func syncCompletionHelper() {
        if let sharingGroups = try? Services.session.syncServer.sharingGroups() {
            self.sharingGroups = sharingGroups.enumerated().map { index, group in
                return SharingGroupData(id: group.sharingGroupUUID, name: group.sharingGroupName ?? "Album \(index)")
            }
        }
    }
}
