
import Foundation
import SwiftUI
import SFSafeSymbols
import iOSShared

enum ObjectDetailsViewActiveSheet: Identifiable {
    case comments
    case editKeywords
    
    var id: Int {
        hashValue
    }
}

struct ObjectDetailsView: View {
    let object:ServerObjectModel
    @ObservedObject var model:ObjectDetailsModel
    @State var menuShown = false
    @StateObject var alerty = AlertySubscriber(debugMessage: "ObjectDetailsView", publisher: Services.session.userEvents)
    @State var activeSheet:ObjectDetailsViewActiveSheet?
    
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
                // A bit of a hack due to [1]. 
                if menuShown {
                    menuShown = false
                    return
                }
                
                if model.modelInitialized {
                    activeSheet = .comments
                }
            })
            
            // To push the `AnyLargeMedia` to the top.
            Spacer()
        }
        .toolbar {
            // Hack, workaround. Without this, I don't get the "< Back" in the uppper left. Or it disappears when I use the "Delete" menu item then cancel. See also https://stackoverflow.com/questions/64405106
            //ToolbarItem(placement: .navigationBarLeading) {Text("")}


            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ObjectDetailsScreenNavButtons(model: model, activeSheet: $activeSheet, tapBadgePickerMenu: {
                    menuShown.toggle()
                })
                .enabled(model.modelInitialized)
                // .onAppear and .onDisappear don't do what I'd expect here.
                // .onAppear happens when entire ObjectDetailsView appears.
                // .onDisappear doesn't happen when Menu hides.
            }
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .sheetyDisplayer(item: $activeSheet, subscriber: alerty) { item in
            switch item {
            case .comments:
                CommentsView(object: object)
            case .editKeywords:
                EditKeywordsView(model: EditKeywordsModel(object: object))
            }
        }
    }
}

/* [1] Having a problem where if you tap on the Menu, it shows comments. This isn't a problem on iPhone, but is a problem on iPad-- somehow it causes:

2021-06-25 20:42:33.061052-0600 Neebla[4292:1693349] [Presentation] Attempt to present <_TtGC7SwiftUI29PresentationHostingControllerVS_7AnyView_: 0x10d031530> on <_TtGC7SwiftUI19UIHostingControllerGVS_15ModifiedContentV6Neebla8MainViewGVS_30_EnvironmentKeyWritingModifierGSqCS2_6AppEnv____: 0x10d0150e0> (from <_TtGC7SwiftUIP10$1a281c62428DestinationHostingControllerVS_7AnyView_: 0x108dcf1f0>) which is already presenting <_UIContextMenuActionsOnlyViewController: 0x10d517eb0>.

And then you can't show the comments after that without exiting the details screen and coming back.
See https://stackoverflow.com/questions/66435927

Previously, I only had:
    @State var showComments = false
I'm now introducing a second bool.
*/
