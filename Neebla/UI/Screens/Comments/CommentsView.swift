
import SwiftUI
import MessageKit

struct CommentsView: View {
    static let buttonBarHeight: CGFloat = 45
    var model: CommentsViewModel?
    @Environment(\.presentationMode) var isPresented
    @ObservedObject var userAlertModel:UserAlertModel
    
    init(object:ServerObjectModel, userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        model = CommentsViewModel(object: object, userAlertModel: userAlertModel)
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
