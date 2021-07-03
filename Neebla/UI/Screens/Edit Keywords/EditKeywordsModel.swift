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
import SQLite

class EditKeywordsModel: NSObject, ObservableObject {
    var object:ServerObjectModel
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

    private var possibleNewKeyword: String?
    var syncSubscription: AnyCancellable!
    
    init(object:ServerObjectModel) {
        self.object = object
        super.init()
        
        do {
            mediaItemAttributesFileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
        } catch let error {
            logger.error("Couldn't load mediaItemAttributesFileModel \(error)")
        }
        
        setupItemKeyword()
        
        // Initialize this second because it uses the current value of `currentMediaItemKeywords`.
        setupAlbumKeywords()
    }
    
    private func setupItemKeyword() {
        setCurrentMediaItemKeywords(keywords:
            MediaItemAttributes.getKeywords(fromCSV: object.keywords))
    }
    
    private func setupAlbumKeywords() {
        do {
            setCurrentAlbumKeywords(keywords: try KeywordModel.keywords(forSharingGroupUUID: object.sharingGroupUUID, deleted: false, db: Services.session.db))
        } catch let error {
            logger.error("Could not get keywords: \(error)")
            setCurrentAlbumKeywords(keywords:[])
        }
    }
    
    // This is because the keywords may have changed and because we're using @StateObject, the model doesn't get re-inited.
    func reFetch() {
        do {
            if let object = try ServerObjectModel.fetchSingleRow(db: Services.session.db, where: ServerObjectModel.fileGroupUUIDField.description == object.fileGroupUUID) {
            
                // Without this condition, I'm getting a broken "Add" button in text field toolbar.
                if self.object.keywords != object.keywords {
                    self.object = object
                    setupItemKeyword()
                }
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    @objc func addButtonAction() {
        guard let possibleNewKeyword = possibleNewKeyword else {
            return
        }
        
        let result = actuallyReadyToAdd(currentText: possibleNewKeyword)
        switch result {
        case .allCharactersTrimmed:
            showAlert(AlertyHelper.alert(title: "Alert!", message: "Your keyword was changed to remove non-allowed characters; all characters were removed."))
            
        case .existingKeyword:
            showAlert(AlertyHelper.alert(title: "Alert!", message: "Your keyword has already been added the media item."))
            
        case .readyNoTrimming(let newKeyword):
            do {
                try changeKeyword(keyword: newKeyword, used: true)
            } catch let error {
                logger.error("Could not add keyword: \(error)")
            }
            
        case .readyTrimmed(let newKeyword):
            showAlert(AlertyHelper.customAction(title: "Alert!", message: "Your keyword was changed to remove characters that are not allowed.\nIt is now: \"\(newKeyword)\"", actionButtonTitle: "Still add?", action: {
                do {
                    try self.changeKeyword(keyword: newKeyword, used: true)
                } catch let error {
                    logger.error("Could not add keyword: \(error)")
                }
            }, cancelTitle: "Cancel"))
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
        
        try MediaItemAttributes.updateKeywords(from: currentMediaItemKeywords, objectModel: object)
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
    
    // Not actually going to delete. Going to mark as deleted. If we just delete it'll come back the next time the attributes file gets downloaded.
    func otherKeywordDelete(at offsets: IndexSet) {
        guard offsets.count == 1, let index = offsets.first else {
            return
        }
        
        let keyword = otherKeywords[index]

        do {
            let albumUsesKeyword = try AlbumModel.usesKeyword(keyword, sharingGroupUUID: object.sharingGroupUUID, db: Services.session.db)
            guard !albumUsesKeyword else {
                showAlert(AlertyHelper.alert(title: "Alert!", message: "The keyword is in use in the album and cannot be removed."))
                return
            }
            
            guard let keywordModel = try KeywordModel.fetchSingleRow(db: Services.session.db, where:
                KeywordModel.keywordField.description == keyword &&
                KeywordModel.sharingGroupUUIDField.description == object.sharingGroupUUID &&
                KeywordModel.deletedField.description == false) else {
                logger.error("No KeywordModel")
                return
            }
            
            try keywordModel.update(setters: KeywordModel.deletedField.description <- true)
            currentAlbumKeywords.remove(keyword)
            setCurrentAlbumKeywords(keywords: currentAlbumKeywords)
        } catch let error {
            logger.error("Failed otherKeywordDelete: \(error)")
        }
    }
    
    func allowedKeywordCharacters() -> CharacterSet {
        var allowed = CharacterSet.letters
        allowed.insert("-")
        allowed.formUnion(CharacterSet.decimalDigits)
        return allowed
    }
    
    enum ReadyToAddResult {
        case allCharactersTrimmed
        case existingKeyword
        case readyNoTrimming(newKeyword: String)
        case readyTrimmed(newKeyword: String)
    }
    
    // A double check because Dany showed me some cases about how he got by my initial checks.
    func actuallyReadyToAdd(currentText: String) -> ReadyToAddResult {
        let notAllowed = allowedKeywordCharacters().inverted
        let trimmedText = currentText.trimmingCharacters(in: notAllowed)
        let trimmed = currentText != trimmedText

        let newKeyword = keywordIsNew(keyword: trimmedText)
        let anyCharacters = trimmedText.count > 0
        let enableButton = anyCharacters && newKeyword
        buttonEnabled.send(enableButton)
        
        if !anyCharacters {
            return .allCharactersTrimmed
        }
        
        if !newKeyword {
            return .existingKeyword
        }
        
        if !trimmed {
            return .readyNoTrimming(newKeyword: trimmedText)
        }
        
        return .readyTrimmed(newKeyword: trimmedText)
    }
}

extension EditKeywordsModel: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let positionOriginal = textField.beginningOfDocument
        let cursorLocation = textField.position(from: positionOriginal, offset: (range.location + NSString(string: string).length))
    
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        let notAllowed = allowedKeywordCharacters().inverted
        let trimmedText = updatedText.trimmingCharacters(in: notAllowed)
        
        possibleNewKeyword = trimmedText
        textField.text = trimmedText
        
        let enableAddButton = trimmedText.count > 0 &&
            keywordIsNew(keyword: trimmedText) &&
            mediaItemAttributesFileModel != nil
            
        buttonEnabled.send(enableAddButton)

        if let cursorLoc = cursorLocation {
            textField.selectedTextRange = textField.textRange(from: cursorLoc, to: cursorLoc)
        }
    
        return false
    }
}

