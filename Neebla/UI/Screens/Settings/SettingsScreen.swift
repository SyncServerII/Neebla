
import Foundation
import SwiftUI
import iOSShared

struct SettingsScreen: View {
    var body: some View {
        MenuNavBar(title: "Settings") {
            iPadConditionalScreenBodySizer(iPadBackgroundColor: .screenBackground) {
                SettingsScreenBody()
            }
        }
    }
}

struct SettingsScreenBody: View {
    @ObservedObject var settingsModel = SettingsScreenModel()
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    @State var alert: SwiftUI.Alert?
    
    var body: some View {
        VStack {
            // Using a scroll view because when you rotate to landscape on iPhone, it looks bad without it. Too scrunched up.
            ScrollView(.vertical, showsIndicators: false) {
                SettingsTopContent(settingsModel: settingsModel)
            }
            
            Spacer()
            
            // Separated these out of the `SettingsTopContent` and the scroll view because I think it looks better to have them aligned with the bottom.
            VStack(spacing: 20) {
                Button(action: {
                    settingsModel.sheet = .aboutApp
                }, label: {
                    Text("About")
                })
                
                VStack {
                    Text("Version/Build")
                        .bold()
                    Text(settingsModel.versionAndBuild)
                }
                                
                Button(action: {
                    settingsModel.sheet = .removeUser
                }, label: {
                    Text("Remove yourself")
                })                
                
                Spacer().frame(height: 5)
            }
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .sheetyDisplayer(item: $settingsModel.sheet, subscriber: alerty, onDismiss: {
            if let alert = alert {
                showAlert(alert)
            }
        }) { sheet in
            switch sheet {
            case .albumList:
                AlbumListModal(specifics: settingsModel.deletionSpecifics, alert: $alert)
            case .emailDeveloper(let addAttachments):
                MailView(emailContents: EmailDeveloper.developer, addAttachments: addAttachments, result: $settingsModel.sendMailResult)
            case .aboutApp:
                AboutApp()
            case .removeUser:
                RemoveUserSheet()
            }
        }
    }
}


