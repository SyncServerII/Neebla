
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
    @Environment(\.colorScheme) var colorScheme
    let emailDeveloper = EmailContents(subject: "Question or comment for developer of Neebla", to: "chris@SpasticMuffin.biz")
    @ObservedObject var settingsModel = SettingsScreenModel()
    let textFieldWidth: CGFloat = 250
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    
    var body: some View {
        // Using a scroll view because when you rotate to landscape on iPhone, it looks bad without it. Too scrunched up.
        ScrollView {
            VStack(spacing: 40) {
                Spacer().frame(height: 20)
                
                VStack {
                    Text("User Name")
                        .bold()
                        
                    TextField("User name", text: $settingsModel.userName ?? "")
                        .multilineTextAlignment(.center)
                        .padding(5)
                        .border(colorScheme == .dark ? Color.black : Color(UIColor.lightGray))
                        .frame(
                            // I tried using a GeometryReader here to make this width a function of screen width, but that breaks the center alignment of the VStack. Grrrr.
                            width: textFieldWidth
                        )
                        // Background color of TextField is fine in non-dark mode. But in dark mode, by default the user can't see the outline of the text field-- and I like them to be able to do that.
                        .if(colorScheme == .dark) {
                            $0.background(Color(UIColor.darkGray))
                        }
                        
                    HStack {
                        Button(action: {
                            settingsModel.updateUserNameOnServer(userName: settingsModel.userName) { success in
                                if success {
                                    hideKeyboard()
                                }
                            }
                        }, label: {
                            Text("Update")
                        })
                        .enabled(settingsModel.userNameChangeIsValid)

                        Button(action: {
                            settingsModel.userName = settingsModel.initialUserName
                        }, label: {
                            Text("(Reset)")
                        })
                        .isHiddenRemove(settingsModel.userName == settingsModel.initialUserName)
                    }
                }
                
                Button(action: {
                    settingsModel.sheet = .albumList
                }, label: {
                    Text("Remove yourself from an album")
                })
                
                Button(action: {
                    let action = {
                        settingsModel.sheet = .emailDeveloper(addAttachments: settingsModel)
                    }
                    let cancelAction = {
                        settingsModel.sheet = .emailDeveloper(addAttachments: nil)
                    }
                    showAlert(AlertyHelper.customAction(title: "Send logs?", message: "Would you like to send Neebla's logs to the developer?", actionButtonTitle: "Yes", action: action, cancelTitle: "No", cancelAction: cancelAction))
                }, label: {
                    Text("Contact developer")
                })
                
                Spacer()
                
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
                
                Spacer().frame(height: 20)
            } // end VStack
        } // end ScrollView
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .sheetyDisplayer(item: $settingsModel.sheet, subscriber: alerty) { sheet in
            switch sheet {
            case .albumList:
                AlbumListModal()
            case .emailDeveloper(let addAttachments):
                MailView(emailContents: emailDeveloper, addAttachments: addAttachments, result: $settingsModel.sendMailResult)
            case .aboutApp:
                AboutApp()
            }
        }
    }
}
