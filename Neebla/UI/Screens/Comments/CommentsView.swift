
import SwiftUI
import MessageKit

struct CommentsView: View {
    static let buttonBarHeight: CGFloat = 45
    var model: CommentsViewModel?
    @Environment(\.presentationMode) var isPresented
    
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
        
            if let model = model {
                MessagesView(model: model)
            }
            else {
                Text("No comments available")
            }
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
