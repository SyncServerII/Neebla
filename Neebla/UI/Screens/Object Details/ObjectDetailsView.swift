
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct ObjectDetailsView: View {
    @Environment(\.presentationMode) var isPresented
    let object:ServerObjectModel
    @ObservedObject var model:ObjectDetailsModel
    @State var showComments = false
    @StateObject var alerty = AlertySubscriber(debugMessage: "ObjectDetailsView", publisher: Services.session.userEvents)
    @StateObject var signInManager = Services.session.signInServices.manager
    
    init(object:ServerObjectModel) {
        self.object = object
        model = ObjectDetailsModel(object: object)
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
                        model.promptForDeletion(dismiss: {
                            isPresented.wrappedValue.dismiss()
                        })
                    },
                    label: {
                        SFSymbolIcon(symbol: .trash)
                    }
                )
                .enabled(signInManager.userIsSignedIn == true)
                
                Button(
                    action: {
                        showComments = true
                    },
                    label: {
                        SFSymbolIcon(symbol: .message)
                    }
                )
            }.enabled(model.modelInitialized)
        )
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .sheetyDisplayer(show: $showComments, subscriber: alerty, view: CommentsView(object: object))
    }
}
