
import SwiftUI
import MessageKit
import iOSShared

struct CommentsView: View {
    static let buttonBarHeight: CGFloat = 45
    var model: CommentsViewModel?
    @Environment(\.presentationMode) var isPresented
    @StateObject var alerty = AlertySubscriber(debugMessage: "CommentsView", publisher: Services.session.userEvents)

    init(object:ServerObjectModel) {
        model = CommentsViewModel(object: object)
    }
    
    var body: some View {
        VStack {
            ZStack {
                TopView {
                   Button(action: {
                        isPresented.wrappedValue.dismiss()
                    }, label: {
                        SFSymbolIcon(symbol: .multiplyCircle)
                    })
                        
                    Spacer()
                }

                TopView {
                    Spacer()
                    Text("Discussion")
                    Spacer()
                }
            }
        
            if let model = model {
                MessagesView(model: model)
            }
            else {
                // This covers the "gone" case as well. I don't see any reason so far to distinguish the gone case specifically.
                Spacer()
                Text("No comments available")
                Spacer()
            }
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .onAppear() {
            // The user is viewing comments. Reset the (local) unread count.
            model?.markAllRead()
        }
    }
}
