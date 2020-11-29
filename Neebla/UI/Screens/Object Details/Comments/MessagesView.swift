//
//  MessagesView.swift
//  ChatExample
//
//  Created by Kino Roy on 2020-07-18.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import SwiftUI
import MessageKit
import InputBarAccessoryView
import iOSShared

// Adapted from https://github.com/MessageKit/MessageKit

final class MessageSwiftUIVC: MessagesViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 2/13/18; See https://github.com/crspybits/SharedImages/issues/81 and see https://github.com/MessageKit/MessageKit/issues/518
        messageInputBar.sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 22.0)
        
        messageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Because SwiftUI wont automatically make our controller the first responder, we need to do it on viewDidAppear
        becomeFirstResponder()
        messagesCollectionView.scrollToBottom(animated: true)
    }
}

@available(iOS 13.0, *)
struct MessagesView: UIViewControllerRepresentable {
    @State var initialized = false
    @ObservedObject var model: MessagesViewModel
    
    init(model: MessagesViewModel){
        self.model = model
    }
    
    func makeUIViewController(context: Context) -> MessagesViewController {
        let messagesVC = MessageSwiftUIVC()
        
        messagesVC.messagesCollectionView.messagesDisplayDelegate = context.coordinator
        messagesVC.messagesCollectionView.messagesLayoutDelegate = context.coordinator
        messagesVC.messagesCollectionView.messagesDataSource = context.coordinator
        messagesVC.messagesCollectionView.messageCellDelegate = context.coordinator
        messagesVC.messageInputBar.delegate = context.coordinator
        messagesVC.scrollsToBottomOnKeyboardBeginsEditing = true // default false
        messagesVC.maintainPositionOnKeyboardFrameChanged = true // default false
        messagesVC.showMessageTimestampOnSwipeLeft = true // default false
        context.coordinator.messagesCollectionView = messagesVC.messagesCollectionView
        
        return messagesVC
    }
    
    func updateUIViewController(_ uiViewController: MessagesViewController, context: Context) {
        uiViewController.messagesCollectionView.reloadData()
        scrollToBottom(uiViewController)
    }
    
    private func scrollToBottom(_ uiViewController: MessagesViewController) {
        DispatchQueue.main.async {
            // The initialized state variable allows us to start at the bottom with the initial messages without seeing the inital scroll flash by
            uiViewController.messagesCollectionView.scrollToBottom(animated: self.initialized)
            self.initialized = true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(model: model)
    }
    
    final class Coordinator {
        weak var messagesCollectionView:MessagesCollectionView!
        
        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()
        
        @ObservedObject var model:MessagesViewModel
        
        init(model:MessagesViewModel) {
            self.model = model
        }
    }
}

@available(iOS 13.0, *)
extension MessagesView.Coordinator: MessagesDataSource {
    func currentSender() -> SenderType {
        return Sender(senderId: model.senderUserId, displayName: model.senderUserDisplayName)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return model.messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return model.messages.count
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    /*
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }*/

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        struct BottomDateFormatter {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                // See https://nsdateformatter.com
                formatter.dateFormat = "MMM d, h:mm a"
                return formatter
            }()
        }
        
        let formatter = BottomDateFormatter.formatter
        let dateString = formatter.string(from: message.sentDate)
        let result = NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
        return result
    }

    func messageTimestampLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let sentDate = message.sentDate
        let sentDateString = MessageKitDateFormatter.shared.string(from: sentDate)
        let timeLabelFont: UIFont = .boldSystemFont(ofSize: 10)
        let timeLabelColor: UIColor = .systemGray
        return NSAttributedString(string: sentDateString, attributes: [NSAttributedString.Key.font: timeLabelFont, NSAttributedString.Key.foregroundColor: timeLabelColor])
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        struct CellDateFormatter {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                // See https://nsdateformatter.com
                formatter.dateFormat = "EEEE, MMM d, yyyy"
                return formatter
            }()
        }
        
        if !isPreviousMessageSameDay(at: indexPath) {
            let formatter = CellDateFormatter.formatter
            let dateString = formatter.string(from: message.sentDate)
            return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        
        return nil
    }
}

@available(iOS 13.0, *)
extension MessagesView.Coordinator: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        var success = false
        
        for component in inputBar.inputTextView.components {
            if let text = component as? String {
                let messageUUID = UUID().uuidString
                let message = DiscussionMessage(messageId: messageUUID, sender: currentSender(), sentDate: Date(), sentTimezone: TimeZone.current.identifier, kind: .text(text))
                success = model.addNewMessage(message)
                if success {
                    messagesCollectionView.insertSections([model.messages.count - 1])
                }
            }
        }
        
        if success {
            inputBar.inputTextView.text = String()
            messagesCollectionView.scrollToBottom()
        }
    }
    
    func messageInputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        if text.count > MessagesViewModel.maxMessageLength {
            let last = text.index(text.startIndex, offsetBy: MessagesViewModel.maxMessageLength)
            inputBar.inputTextView.text = String(text[..<last])
        }
    }
}

@available(iOS 13.0, *)
extension MessagesView.Coordinator: MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let initials = model.getInitialsFromSenderDisplayName(sender: message.sender)
        let avatar = Avatar(initials: initials)
        avatarView.set(avatar: avatar)
    }
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        return MessageLabel.defaultAttributes
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }

    // MARK: - All Messages

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
}

extension MessagesView.Coordinator: MessagesLayoutDelegate {
    private func isPreviousMessageSameDay(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        
        let currentMessage = messageForItem(at: indexPath, in: messagesCollectionView)
        let currentMessageDate = currentMessage.sentDate
        
        let previousIndexPath = IndexPath(row: 0, section: indexPath.section - 1)
        let previousMessage = messageForItem(at: previousIndexPath, in: messagesCollectionView)
        let previousMessageDate = previousMessage.sentDate
        
        return Calendar.current.isDate(currentMessageDate, inSameDayAs:previousMessageDate)
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isPreviousMessageSameDay(at: indexPath) {
            return 10
        }
        else {
            return 35
        }
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }

    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }
    
    // Prior to version 2.0.0 of MessageKit, I had a cellTopLabelAlignment delegate method in here (nor cellBottomLabelAlignment). Seems like (a) it's been removed and (b) it's not needed any more. See also https://github.com/MessageKit/MessageKit/issues/1041 and https://stackoverflow.com/questions/52583843/migration-to-1-0-0-messagekit-cocoapod-with-messageslayoutdelegate

    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {

        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
    }

    // MARK: - Location Messages

    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
}

extension MessagesView.Coordinator: MessageCellDelegate {
    func didSelectURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        phoneNumber.makeACall()
    }
    
    func didSelectAddress(_ addressComponents: [String : String]) {
        // It's not documented, but the keys are from NSTextCheckingKey. Having to do some machinations to get just a simple address string again to geocode it. See also https://github.com/MessageKit/MessageKit/issues/1043
        let keys = [NSTextCheckingKey.street.rawValue, NSTextCheckingKey.city.rawValue, NSTextCheckingKey.state.rawValue, NSTextCheckingKey.zip.rawValue]
        var address = ""
        
        for key in keys {
            if let value = addressComponents[key] {
                if address.count > 0 {
                    address += ", "
                }
                
                address += value
            }
        }
        
        guard address.count > 0 else {
            return
        }
    
        #warning("FIX ME")
        // AddressNavigation.navigate(to: address, using: self)
    }
}

// From https://stackoverflow.com/questions/40078370/how-to-make-phone-call-in-ios-10-using-swift/52644570
extension String {
    enum RegularExpressions: String {
        case phone = "^\\s*(?:\\+?(\\d{1,3}))?([-. (]*(\\d{3})[-. )]*)?((\\d{3})[-. ]*(\\d{2,4})(?:[-.x ]*(\\d+))?)\\s*$"
    }

    func isValid(regex: RegularExpressions) -> Bool {
        return isValid(regex: regex.rawValue)
    }

    func isValid(regex: String) -> Bool {
        let matches = range(of: regex, options: .regularExpression)
        return matches != nil
    }

    func onlyDigits() -> String {
        let filtredUnicodeScalars = unicodeScalars.filter{CharacterSet.decimalDigits.contains($0)}
        return String(String.UnicodeScalarView(filtredUnicodeScalars))
    }

    func makeACall() {
        if isValid(regex: .phone) {
            if let url = URL(string: "tel://\(self.onlyDigits())"), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
}
