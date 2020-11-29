
import SwiftUI
import MessageKit

struct CommentsView: View {
    static let buttonBarHeight: CGFloat = 70
    let model: MessagesViewModel
    @Environment(\.presentationMode) var isPresented
    
    init(model:MessagesViewModel) {
        self.model = model
    }
    
    var body: some View {
        // ZStack and friends to get the message view scrolling to come up *under* the button bar.
        ZStack {
            VStack {
                Spacer()
                    .frame(height: Self.buttonBarHeight)
                MessagesView(model: model)
            }
            
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
                .background(Color.white)
                
                Spacer()
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
        // Bring the button bar up to approx. the top of the sheet modal
        .offset(y: -10)
    }
}
