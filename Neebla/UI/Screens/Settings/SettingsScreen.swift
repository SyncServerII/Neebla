
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
                    .border(Color.black)
                    .frame(
                        // I tried using a GeometryReader here to make this width a function of screen width, but that breaks the center alignment of the VStack. Grrrr.
                        width: textFieldWidth
                    )
                    
                Button(action: {
                    settingsModel.updateUserName(userName: settingsModel.userName)
                }, label: {
                    Text("Update")
                })
                .enabled(settingsModel.initialUserName != settingsModel.userName)
            }
            
            Button(action: {
                settingsModel.sheet = .albumList
                settingsModel.showSheet = true
            }, label: {
                Text("Remove user from album")
            })
            
            Button(action: {
                settingsModel.sheet = .emailDeveloper
                settingsModel.showSheet = true
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
            if settingsModel.sheet == .albumList {
                AlbumListModal()
            }
            else if settingsModel.sheet == .emailDeveloper {
                MailView(emailContents: emailDeveloper, result: $settingsModel.sendMailResult)
            }
        }
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
    }
}
