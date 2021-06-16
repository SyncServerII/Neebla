
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

struct ObjectDetailsView: View {
    let object:ServerObjectModel
    @ObservedObject var model:ObjectDetailsModel
    @State var showComments = false
    @StateObject var alerty = AlertySubscriber(debugMessage: "ObjectDetailsView", publisher: Services.session.userEvents)
    
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
            
            AnyLargeMedia(object: object, tapOnLargeMedia: {
                if model.modelInitialized {
                    showComments = true
                }
            })
            
            // To push the `AnyLargeMedia` to the top.
            Spacer()
        }
        .if(model.badgeView != nil) {
            $0.upperRightView(model.badgeView!)
        }
        .toolbar {
            // Hack, workaround. Without this, I don't get the "< Back" in the uppper left. Or it disappears when I use the "Delete" menu item then cancel. See also https://stackoverflow.com/questions/64405106
            ToolbarItem(placement: .navigationBarLeading) {Text("")}
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ObjectDetailsScreenNavButtons(showComments: $showComments, model: model)
                    .enabled(model.modelInitialized)
            }
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .sheetyDisplayer(show: $showComments, subscriber: alerty, view: CommentsView(object: object))
    }
}
