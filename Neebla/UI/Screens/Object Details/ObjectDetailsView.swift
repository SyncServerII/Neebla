
import Foundation
import SwiftUI
import SFSafeSymbols

struct ObjectDetailsView: View {
    let object:ServerObjectModel
    var model:MessagesViewModel?
    @State var showComments = false
    @State var showDeletion = false
    
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
            
            // To push the `AnyLargeMedia` to the top.
            Spacer()
        }
        .navigationBarItems(trailing:
            HStack(spacing: 0) {
                Button(
                    action: {
                        showDeletion = true
                    },
                    label: {
                        SFSymbolNavBar(symbol: .trash)
                    }
                )
                
                Button(
                    action: {
                        showComments = true
                    },
                    label: {
                        SFSymbolNavBar(symbol: .message)
                    }
                )
            }.enabled(model != nil)
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
        .alert(isPresented: $showDeletion) {
            // Should never default to "item"
            let displayName = model?.objectTypeDisplayName ?? "item"
            return Alert(
                title:
                    Text("Really delete this \(displayName)?"),
                primaryButton: .cancel(),
                secondaryButton:
                    .destructive(
                        Text("Delete"),
                        action: {
                
                        }
                    )
                )
        }
    }
}
