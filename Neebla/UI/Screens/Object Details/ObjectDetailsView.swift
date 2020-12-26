
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct ObjectDetailsView: View {
    @Environment(\.presentationMode) var isPresented
    let object:ServerObjectModel
    @ObservedObject var model:ObjectDetailsModel
    @State var showComments = false
    @State var showDeletion = false
    @ObservedObject var userAlertModel:UserAlertModel

    init(object:ServerObjectModel) {
        self.object = object
        let userAlertModel = UserAlertModel()
        model = ObjectDetailsModel(object: object, userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }
    
    var body: some View {
        VStack {
            if let title = model.mediaTitle {
                Text(title)
                    .padding(.top, 10)
            }
            
            AnyLargeMedia(object: object)
                .onTapGesture {
                    if model.modelInitialized {
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
            }.enabled(model.modelInitialized)
        )
        .sheet(isPresented: $showComments) {
            CommentsView(object: object)
        }
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
        .alert(isPresented: $showDeletion) {
            // Should never default to "item"
            let displayName = model.objectTypeDisplayName ?? "item"
            return Alert(
                title:
                    Text("Really delete this \(displayName)?"),
                primaryButton: .cancel(),
                secondaryButton:
                    .destructive(
                        Text("Delete"),
                        action: {
                            if model.modelInitialized {
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
