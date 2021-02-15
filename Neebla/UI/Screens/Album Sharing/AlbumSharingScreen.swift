
import SwiftUI
import iOSShared

struct AlbumSharingScreen: View {
    var body: some View {
        MenuNavBar(title: "Album Sharing") {
            iPadConditionalScreenBodySizer {
                AlbumSharingScreenBody()
                    .background(Color.screenBackground)
            }
        }
    }
}

struct AlbumSharingScreenBody: View {
    @StateObject var model = AlbumSharingScreenModel()
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)

    var body: some View {
        VStack {
            HStack {
                Text("Sharing code")
                Spacer()
            }
            
            TextField("Paste sharing code here", text: $model.sharingCode ?? "")
                
            Spacer().frame(height: 50)
            
            HStack {
                Button(action: {
                    model.acceptSharingInvitation()
                }, label: {
                    Text("Accept sharing invitation")
                })
                .enabled(model.enableAcceptSharingInvitation)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(30)
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
    }
}

