
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
    @ObservedObject var userAlertModel: UserAlertModel
    @ObservedObject var settingsModel:SettingsScreenModel

    var versionAndBuild:String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return version + "/" + build
        }
        else {
            return "(Unavailable)"
        }
    }
    
    init() {
        let userAlertModel = UserAlertModel()
        self.settingsModel = SettingsScreenModel(userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }
        
    var body: some View {
        VStack(spacing: 40) {
            Spacer().frame(height: 20)
            
            Button(action: {
                settingsModel.showAlbumList = true
            }, label: {
                Text("Remove user from album")
            })
            
            Button(action: {
            }, label: {
                Text("Contact developer")
            })
            
            Spacer()
            
            VStack {
                Text("Version/Build")
                    .bold()
                Text(versionAndBuild)
            }
            
            Spacer().frame(height: 20)
        }
        .sheet(isPresented: $settingsModel.showAlbumList) {
            AlbumListModal()
        }
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
    }
}
