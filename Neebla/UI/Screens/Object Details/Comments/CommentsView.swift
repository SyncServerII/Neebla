
import SwiftUI
import MessageKit

struct CommentsView: View {
    @Environment(\.presentationMode) var isPresented
    static let sender = Sender(senderId: "1", displayName: "Chris")

    @State var messages: [MessageType] = [
        MockMessage(sender: Self.sender, messageId: "1", sentDate: Date(), kind: .text("Foo")),
        MockMessage(sender: Self.sender, messageId: "1", sentDate: Date(), kind: .text("Foo"))
    ]
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    isPresented.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                })
                .padding([.leading, .top], 10)
                Spacer()
            }
            
            MessagesView(messages: $messages)
        }
    }
}
