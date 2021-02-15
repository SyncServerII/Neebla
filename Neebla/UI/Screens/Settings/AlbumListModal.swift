
import Foundation
import SwiftUI
import iOSShared

struct AlbumListModal: View {
    @ObservedObject var model = AlbumListModalModel()
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    
    var body: some View {
        VStack(spacing: 20) {
            ScreenButtons(model: model)
            
            Text("Select album to delete:")

            List {
                ForEach(model.albums, id: \.sharingGroupUUID) { album in
                    AlbumRow(album: album, model: model)
                }
            }
        }
        .padding(20)
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
    }
}

private struct AlbumRow: View {
    let album:AlbumModel
    let model:AlbumListModalModel
    
    var albumName: String {
        return album.albumName ?? AlbumModel.untitledAlbumName
    }
    
    init(album:AlbumModel, model:AlbumListModalModel) {
        self.album = album
        self.model = model
    }
    
    var body: some View {
        Button(action: {
            let alert = AlertyHelper.customAction(
                title: "Delete album?",
                message: "This will remove you from the album \"\(albumName)\". And if you are the last one using the album, will entirely remove the album.",
                actionButtonTitle: "Remove",
                action: {
                    model.removeUserFromAlbum(album: album)
                },
                cancelTitle: "Cancel")
            showAlert(alert)
        }, label: {
            Text(albumName)
        })
    }
}

private struct ScreenButtons: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var model:AlbumListModalModel
    
    var body: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            
            Spacer()
        }
    }
}
