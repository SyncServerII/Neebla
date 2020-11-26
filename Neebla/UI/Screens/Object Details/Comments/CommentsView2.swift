
import SwiftUI
import MessageKit

struct SwiftUIExampleView: View {
    static let sender = Sender(senderId: "1", displayName: "Chris")

    @State var messages: [MessageType] = [
        MockMessage(sender: Self.sender, messageId: "1", sentDate: Date(), kind: .text("Foo")),
        MockMessage(sender: Self.sender, messageId: "1", sentDate: Date(), kind: .text("Foo"))
    ]
    
    var body: some View {
        MessagesView(messages: $messages).onAppear {
        }.onDisappear {
        }
        .navigationBarTitle("SwiftUI Example", displayMode: .inline)
    }
}
