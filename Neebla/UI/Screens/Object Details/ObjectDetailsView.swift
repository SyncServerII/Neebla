
import Foundation
import SwiftUI
import SFSafeSymbols

struct ObjectDetailsView: View {
    @Environment(\.presentationMode) var isPresented
    let object:ServerObjectModel
    var model:ObjectDetailsModel?
    @State var showComments = false
    @State var showDeletion = false
    
    init(object:ServerObjectModel) {
        self.object = object
        model = ObjectDetailsModel(object: object)
    }
    
    var body: some View {
        VStack {
            if let title = model?.mediaTitle {
                Text(title)
                    .padding(.top, 10)
            }
            
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
            CommentsView(object: object)
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
                            if let model = model {
                                if model.deleteObject() {
                                    isPresented.wrappedValue.dismiss()
                                }
                            }
                        }
                    )
                )
        }
    }
}
