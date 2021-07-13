
import Foundation
import SwiftUI
import iOSShared

protocol AlbumListModalSpecifics {
    var albumListHeader: String { get }
    var alertTitle: String { get }
    var actionButtonTitle: String { get }
    func alertMessage(albumName: String) -> String
    func action(album: AlbumModel, completion: ((_ dismiss: Bool)->())?)
    func albumFilter(albums:[AlbumModel]) -> [AlbumModel]
}

extension AlbumListModalSpecifics {
    func albumFilter(albums:[AlbumModel]) -> [AlbumModel] {
        return albums
    }
}

struct AlbumListModal: View {
    @ObservedObject var model = AlbumListModalModel()
    let specifics: AlbumListModalSpecifics
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    
    var body: some View {
        VStack(spacing: 20) {
            ScreenButtons()
            
            Text(specifics.albumListHeader)

            List {
                ForEach(
                    specifics.albumFilter(albums: model.albums),
                    id: \.sharingGroupUUID) { album in
                    AlbumRow(album: album, model: model, specifics: specifics)
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
    let specifics: AlbumListModalSpecifics
    @Environment(\.presentationMode) var presentationMode
    
    var albumName: String {
        return album.albumName ?? AlbumModel.untitledAlbumName
    }
    
    init(album:AlbumModel, model:AlbumListModalModel, specifics: AlbumListModalSpecifics) {
        self.album = album
        self.model = model
        self.specifics = specifics
    }
    
    var body: some View {
        Button(action: {
            let alert = AlertyHelper.customAction(
                title: specifics.alertTitle,
                message: specifics.alertMessage(albumName: albumName),
                actionButtonTitle: specifics.actionButtonTitle,
                action: {
                    specifics.action(album: album, completion: { dismiss in
                        if dismiss {
                            presentationMode.wrappedValue.dismiss()
                        }
                    })
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
