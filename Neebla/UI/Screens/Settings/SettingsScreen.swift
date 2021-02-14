
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
    @ObservedObject var userAlertModel: UserAlertModel
    @ObservedObject var settingsModel:SettingsScreenModel
    let textFieldWidth: CGFloat = 250
    
    init() {
        let userAlertModel = UserAlertModel()
        self.settingsModel = SettingsScreenModel(userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }
        
    var body: some View {
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
                        settingsModel.updateUserName(userName: settingsModel.userName) { success in
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
                settingsModel.showSheet = true
            }, label: {
                Text("Remove yourself from an album")
            })
            
            Button(action: {
                let action = {
                    settingsModel.sheet = .emailDeveloper(addAttachments: settingsModel)
                    settingsModel.showSheet = true
                }
                let cancelAction = {
                    settingsModel.sheet = .emailDeveloper(addAttachments: nil)
                    settingsModel.showSheet = true
                }
                
                userAlertModel.userAlert = .customDetailedAction(title: "Send logs?", message: "Would you like to send Neebla's logs to the developer?", actionButtonTitle:"Yes", action:action, cancelTitle: "No", cancelAction:cancelAction)
            }, label: {
                Text("Contact developer")
            })
            
            Spacer()
            
            VStack {
                Text("Version/Build")
                    .bold()
                Text(settingsModel.versionAndBuild)
            }
            
            Spacer().frame(height: 20)
        } // end VStack
        .sheet(isPresented: $settingsModel.showSheet) {
            switch settingsModel.sheet {
            case .albumList:
                AlbumListModal()
            case .emailDeveloper(let addAttachments):
                MailView(emailContents: emailDeveloper, addAttachments: addAttachments, result: $settingsModel.sendMailResult)
            case .none:
                Text("Error: Should not appear")
            }
        }
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
    }
}
