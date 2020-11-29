
import Foundation
import SwiftUI
import SFSafeSymbols

struct ObjectDetailsView: View {
    let object:ServerObjectModel
    var model:MessagesViewModel?
    @State var showComments = false
    
    init(object:ServerObjectModel) {
        self.object = object
        model = MessagesViewModel(object: object)
    }
    
    var body: some View {
        VStack {
            AnyLargeMedia(object: object)
                .onTapGesture {
                    if let _ = model {
                        showComments = true
                    }
                }
                
            Spacer()
        }
        .navigationBarItems(trailing:
            Button(
                action: {
                    showComments = true
                },
                label: {
                    SFSymbolNavBar(symbol: .message)
                }
            )
            .enabled(model != nil)
        )
        .sheet(isPresented: $showComments) {
            if let model = model {
                CommentsView(model: model)
            }
            else {
                // Should never get here. Should never have showComments == true when model is nil.
                EmptyView()
            }
        }
    }
}
