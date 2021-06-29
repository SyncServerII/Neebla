//
//  EditKeywordsModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/27/21.
//

import Foundation
import UIKit
import Combine
import iOSShared
import ChangeResolvers
import iOSBasics

class EditKeywordsModel: NSObject, ObservableObject {
    let object:ServerObjectModel
    let buttonEnabled = PassthroughSubject<Bool, Never>()
    
    var textFieldOptions:TextFieldOptions {
        TextFieldOptions(buttonTarget: self, buttonAction: #selector(addButtonAction), delegate: self, buttonEnabled: buttonEnabled)
    }
    
    private var mediaItemAttributesFileModel:ServerFileModel!
    private var currentAlbumKeywords: Set<String>!
    private var currentMediaItemKeywords: Set<String>!
    @Published var keywords = [String]()
    @Published var otherKeywords = [String]()
    
    func setCurrentMediaItemKeywords(keywords: Set<String>) {
        currentMediaItemKeywords = keywords
        self.keywords = Array(currentMediaItemKeywords).sorted()
        
        if let currentAlbumKeywords = currentAlbumKeywords {
            setCurrentAlbumKeywords(keywords: currentAlbumKeywords)
        }
    }
    
    func setCurrentAlbumKeywords(keywords: Set<String>) {
        currentAlbumKeywords = keywords
        
        // Don't bother showing keywords already in the specific media item.
        let other = currentAlbumKeywords.subtracting(currentMediaItemKeywords)
        otherKeywords = Array(other).sorted()
    }

    private var newKeyword: String?
    var syncSubscription: AnyCancellable!
    
    init(object:ServerObjectModel) {
        self.object = object
        super.init()
        
        do {
            mediaItemAttributesFileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
            setCurrentMediaItemKeywords(keywords:
                MediaItemAttributes.getKeywords(fromCSV: mediaItemAttributesFileModel.keywords))
        } catch let error {
            // Hmmm. We don't have a media attributes model. We should have.
            // We can't change keywords without it. I'm cheating a bit below for now. Not going to allow adding a keyword if mediaItemAttributesFileModel is nil.
            setCurrentMediaItemKeywords(keywords:[])
            logger.error("Couldn't load mediaItemAttributesFileModel: Can't change keywords: \(error)")
        }
        
        // Initialize this second because it uses the current value of `currentMediaItemKeywords`.
        do {
            setCurrentAlbumKeywords(keywords: try KeywordModel.keywords(forSharingGroupUUID: object.sharingGroupUUID, db: Services.session.db))
        } catch let error {
            logger.error("Could not get keywords: \(error)")
            setCurrentAlbumKeywords(keywords:[])
        }
    }
    
    @objc func addButtonAction() {
        guard let newKeyword = newKeyword else {
            return
        }
        
        do {
            try changeKeyword(keyword: newKeyword, used: true)
        } catch let error {
            logger.error("Could not add keyword: \(error)")
        }
    }
    
    func keywordIsNew(keyword: String) -> Bool {
        let haveThisKeywordAlready = currentMediaItemKeywords.contains(keyword)
        return !haveThisKeywordAlready
    }
    
    func changeKeyword(keyword: String, used: Bool) throws {
        guard let mediaItemAttributesFileModel = mediaItemAttributesFileModel else {
            return
        }
                        
        let encoder = JSONEncoder()
        let keyValue = KeyValue.keyword(keyword, used: used)
        let data = try encoder.encode(keyValue)

        // Chosing to not inform others of badge-related changes.
        let file = FileUpload.informNoOne(fileLabel: FileLabels.mediaItemAttributes, dataSource: .data(data), uuid: mediaItemAttributesFileModel.fileUUID)
        
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: mediaItemAttributesFileModel.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, uploads: [file])
        try Services.session.syncServer.queue(upload: upload)
        
        if used {
            currentMediaItemKeywords.insert(keyword)
            setCurrentMediaItemKeywords(keywords: currentMediaItemKeywords)
            
            if !currentAlbumKeywords.contains(keyword) {
                let keywordModel = try KeywordModel(db: Services.session.db, sharingGroupUUID: object.sharingGroupUUID, keyword: keyword)
                try keywordModel.insert()
                currentAlbumKeywords.insert(keyword)
                setCurrentAlbumKeywords(keywords: currentAlbumKeywords)
            }
        }
        else {
            currentMediaItemKeywords.remove(keyword)
            setCurrentMediaItemKeywords(keywords: currentMediaItemKeywords)
        }
        
        try MediaItemAttributes.updateKeywords(from: currentMediaItemKeywords, mediaItemAttributesFileModel: mediaItemAttributesFileModel)
    }
    
    func addKeywordWithPrompt(keyword: String) {
        showAlert(
            AlertyHelper.customAction(
                title: "Add keyword?",
                message: "Add keyword '\(keyword)' to this media item?",
                actionButtonTitle: "Add",
                action: {
                    // Retaining self. Otherwise, losing it.
                    do {
                        try self.changeKeyword(keyword: keyword, used: true)
                    } catch let error {
                        logger.error("Failed adding keyword: \(keyword); \(error)")
                    }
                },
                cancelTitle: "Cancel"))
    }
    
    func delete(at offsets: IndexSet) {
        guard offsets.count == 1, let index = offsets.first else {
            return
        }
        
        let keyword = keywords[index]
        
        do {
            try self.changeKeyword(keyword: keyword, used: false)
        } catch let error {
            logger.error("Failed removing keyword: \(keyword); \(error)")
        }
    }
}

extension EditKeywordsModel: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }

        var updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        var allowed = CharacterSet.letters
        allowed.insert("-")
        let notAllowed = allowed.inverted
        
        updatedText = updatedText.trimmingCharacters(in: notAllowed)
        textField.text = updatedText
        
        let enableButton = updatedText.count > 0 &&
            keywordIsNew(keyword: updatedText) &&
            mediaItemAttributesFileModel != nil
                
        if enableButton {
            newKeyword = updatedText
        }
        else {
            newKeyword = nil
        }
        
        buttonEnabled.send(enableButton)
        
        return false
    }
}

