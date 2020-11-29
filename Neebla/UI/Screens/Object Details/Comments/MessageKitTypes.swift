
import Foundation
import MessageKit

struct Sender: SenderType {
    let senderId: String
    let displayName: String
}

struct MockMessage: MessageType {
    let sender: SenderType
    let messageId: String
    var sentDate: Date
    let kind: MessageKind
}
