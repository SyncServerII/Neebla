
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
                Text("No comments available")
            }
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .onAppear() {
            // The user is viewing comments. Reset the (local) unread count.
            model?.resetUnreadCount()
        }
    }
}

private struct TopView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
           content
        }
        .padding([.leading, .top], 10)
        .frame(height: CommentsView.buttonBarHeight)
    }
}
