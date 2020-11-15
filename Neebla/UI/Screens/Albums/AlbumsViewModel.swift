//
//  AlbumsViewModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/13/20.
//

import Foundation

class AlbumsViewModel: ObservableObject {
    @Published var isShowingRefresh = false
    @Published var albums = [AlbumModel]()
    
    @Published var presentAlert = false
    
    @Published var presentTextInput = false
    @Published var textInputAlbumName: String?
    @Published var textInputInitialAlbumName: String?
    @Published var textInputPriorAlbumName: String?
    @Published var textInputActionButtonName: String?
    @Published var textInputNewAlbum: Bool = false
    @Published var textInputTitle: String?
    var textInputAction: (()->())?
    static let untitledAlbumName = "Untitled Album"
    
    var alertMessage: String! {
        didSet {
            presentAlert = alertMessage != nil
        }
    }
    
    init() {
        getCurrentAlbums()
    }

    func getCurrentAlbums() {
        if let albums = try? AlbumModel.fetch(db: Services.session.db) {
            self.albums = albums.sorted(by: { (a1, a2) -> Bool in
                if let name1 = a1.albumName, let name2 = a2.albumName {
                    return name1 < name2
                }
                return false
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
                self.alertMessage = "Failed to create album."
                return
            }
            
            self.sync()
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
                self.alertMessage = "Failed to change album name."
                return
            }
            
            self.sync()
        }
    }
    
    func sync() {
        Services.session.serverInterface.sync() { [weak self] error in
            guard let self = self else { return }
            
            self.isShowingRefresh = false

            guard error == nil else {
                self.alertMessage = "Failed to sync."
                return
            }
            
            self.getCurrentAlbums()
        }
    }
    
    func startChangeExistingAlbumName(sharingGroupUUID: UUID, currentAlbumName: String?) {
        textInputTitle = "Change Album Name:"
        textInputActionButtonName = "Change"
        
        textInputAction = { [weak self] in
            guard let self = self else { return }
            let changedAlbumName = self.textInputAlbumName ?? Self.untitledAlbumName
            self.changeAlbumName(sharingGroupUUID: sharingGroupUUID, changedAlbumName: changedAlbumName)
        }
        
        textInputInitialAlbumName = currentAlbumName ?? Self.untitledAlbumName
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
            let newAlbumName = self.textInputAlbumName ?? Self.untitledAlbumName
            self.createNewAlbum(newAlbumName: newAlbumName)
        }
        
        textInputInitialAlbumName = Self.untitledAlbumName
        textInputAlbumName = nil
        textInputNewAlbum = true
        presentTextInput = true
    }
}
