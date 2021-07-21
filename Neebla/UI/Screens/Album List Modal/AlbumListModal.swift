
import Foundation
import SwiftUI
import iOSShared

enum ActionCompletion {
    // Dissmiss the album list modal, and then show the alert on the parent of the album list modal.
    case dismissAndThenShow(SwiftUI.Alert)
    
    // Don't dismiss the album list modal. Just show the alert.
    case showAlert(SwiftUI.Alert)
}

protocol AlbumListModalSpecifics {
    var albumListHeader: String { get }
    var alertTitle: String { get }
    var actionButtonTitle: String { get }
    func alertMessage(albumName: String) -> String
    func action(album: AlbumModel, completion: ((_ alert: ActionCompletion)->())?)
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
    @Binding var alert: SwiftUI.Alert?
    
    var body: some View {
        VStack(spacing: 20) {
            ScreenButtons()
            
            Text(specifics.albumListHeader)

            List {
                ForEach(
                    specifics.albumFilter(albums: model.albums),
                    id: \.sharingGroupUUID) { album in
                    AlbumRow(album: album, model: model, specifics: specifics, alert: $alert)
                }
            }
        }
        .padding(20)
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .onAppear() {
            alert = nil
        }
    }
}

private struct AlbumRow: View {
    let album:AlbumModel
    let model:AlbumListModalModel
    let specifics: AlbumListModalSpecifics
    @Binding var alert: SwiftUI.Alert?

    @Environment(\.presentationMode) var presentationMode
    
    var albumName: String {
        return album.albumName ?? AlbumModel.untitledAlbumName
    }
    
    var body: some View {
        Button(action: {
            let alert = AlertyHelper.customAction(
                title: specifics.alertTitle,
                message: specifics.alertMessage(albumName: albumName),
                actionButtonTitle: specifics.actionButtonTitle,
                action: {
                    specifics.action(album: album, completion: { alert in
                        switch alert {
                        case .dismissAndThenShow(let alert):
                            self.alert = alert
                            presentationMode.wrappedValue.dismiss()
                        case .showAlert(let alert):
                            showAlert(alert)
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
