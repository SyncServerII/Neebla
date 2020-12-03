
import SwiftUI
import MessageKit

struct CommentsView: View {
    static let buttonBarHeight: CGFloat = 45
    let model: MessagesViewModel
    @Environment(\.presentationMode) var isPresented
    
    init(model:MessagesViewModel) {
        self.model = model
    }
    
    var body: some View {
        VStack {
            ZStack {
                TopView {
                   Button(action: {
                        isPresented.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel")
                    })
                        
                    Spacer()
                }

                TopView {
                    Spacer()
                    Text("Discussion")
                    Spacer()
                }
            }
        
            MessagesView(model: model)
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
