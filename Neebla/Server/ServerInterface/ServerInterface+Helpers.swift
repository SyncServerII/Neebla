//
//  ServerInterface+Helpers.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/3/20.
//

import Foundation
import iOSShared
import ServerShared
import iOSBasics

extension ServerInterface {
    func syncHelper(result: SyncResult) throws {
        switch result {
        case .noIndex:
            break
        case .index(sharingGroupUUID: _, index: let index):
            try index.upsert(db: Services.session.db)
        }

        let sharingGroups = try self.syncServer.sharingGroups()
        try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: sharingGroups)
    }
    
    func sharingGroups() {
        do {
            let sharingGroups = try syncServer.sharingGroups()
            for sharingGroup in sharingGroups {
                logger.info("\(sharingGroup)")
                if firstSharingGroupUUID == nil {
                    firstSharingGroupUUID = sharingGroup.sharingGroupUUID
                }
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func createSharingInvitation(permission: Permission, sharingGroupUUID: UUID, numberAcceptors: UInt, allowSharingAcceptance: Bool) {
        syncServer.createSharingInvitation(withPermission: permission, sharingGroupUUID: sharingGroupUUID, numberAcceptors: numberAcceptors, allowSharingAcceptance: allowSharingAcceptance) { result in
            switch result {
            case .failure(let error):
                logger.error("\(error)")
            case .success(let code):
                let sharingURL = Services.session.signInServices.sharingInvitation.createSharingURL(invitationCode: code.uuidString)
                logger.info("sharingURL: \(sharingURL)")
            }
        }
    }

#if false
    // With a nil fileGroupUUID, creates a new fileGroupUUID.
    func uploadNewFile(sharingGroupUUID: UUID, fileGroupUUID: UUID?, textForFile: String) {
        let fileUUID1 = UUID()

        do {
            let declaration1 = FileDeclaration(uuid: fileUUID1, mimeType: MimeType.text, appMetaData: nil, changeResolverName: nil)
            let declarations = Set<FileDeclaration>([declaration1])
        
            guard let data = textForFile.data(using: .utf8) else {
                throw ServerInterfaceError.cannotConvertStringToData
            }
            
            let uploadable1 = FileUpload(uuid: fileUUID1, dataSource: .data(data))
            let uploadables = Set<FileUpload>([uploadable1])
        
            var fileGroup: UUID
            if let fileGroupUUID = fileGroupUUID {
                fileGroup = fileGroupUUID
            }
            else {
                fileGroup = UUID()
            }
            
            let testObject = ObjectDeclaration(fileGroupUUID: fileGroup, objectType: "foo", sharingGroupUUID: sharingGroupUUID, declaredFiles: declarations)
            
            try syncServer.queue(uploads: uploadables, declaration: testObject)
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func uploadMultipleImageFiles(sharingGroupUUID: UUID) {
        let catImageFile = ("Cat", "jpg")

        let fileUUID1 = UUID()
        let fileUUID2 = UUID()
        let fileUUID3 = UUID()
        let fileUUID4 = UUID()

        do {
            let declaration1 = FileDeclaration(uuid: fileUUID1, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declaration2 = FileDeclaration(uuid: fileUUID2, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declaration3 = FileDeclaration(uuid: fileUUID3, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declaration4 = FileDeclaration(uuid: fileUUID4, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declarations = Set<FileDeclaration>([declaration1, declaration2, declaration3, declaration4])

            guard let exampleCatImageURL = Bundle.main.url(forResource: catImageFile.0, withExtension: catImageFile.1) else {
                throw ServerInterfaceError.cannotFindFile
            }
        
            let uploadable1 = FileUpload(uuid: fileUUID1, dataSource: .immutable(exampleCatImageURL))
            let uploadable2 = FileUpload(uuid: fileUUID2, dataSource: .immutable(exampleCatImageURL))
            let uploadable3 = FileUpload(uuid: fileUUID3, dataSource: .immutable(exampleCatImageURL))
            let uploadable4 = FileUpload(uuid: fileUUID4, dataSource: .immutable(exampleCatImageURL))
            let uploadables = Set<FileUpload>([uploadable1, uploadable2, uploadable3, uploadable4])
        
            let testObject = ObjectDeclaration(fileGroupUUID: UUID(), objectType: "foo", sharingGroupUUID: sharingGroupUUID, declaredFiles: declarations)
            
            try syncServer.queue(uploads: uploadables, declaration: testObject)
        } catch let error {
            logger.error("\(error)")
        }
    }
#endif
}
