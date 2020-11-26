
import Foundation
import SwiftUI
import SFSafeSymbols

struct ObjectDetailsView: View {
    let object:ServerObjectModel
    @State var showComments = false
    
    var body: some View {
        VStack {
            AnyLargeMedia(object: object)
                .onTapGesture {
                    showComments = true
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
        )
        .sheet(isPresented: $showComments) {
            CommentsView()
        }
    }
}
