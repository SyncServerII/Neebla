
import Foundation
import SwiftUI

struct AlbumListModal: View {
    @ObservedObject var model:AlbumListModalModel
    @ObservedObject var userAlertModel: UserAlertModel
    
    init() {
        let userAlertModel = UserAlertModel()
        self.model = AlbumListModalModel(userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }
    
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
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
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
            model.removeUserFromAlbum(album: album)
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
