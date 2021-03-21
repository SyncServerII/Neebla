//
//  SettingsTopContent.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/21/21.
//

import Foundation
import SwiftUI
import iOSShared

struct SettingsTopContent: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var settingsModel:SettingsScreenModel
    let textFieldWidth: CGFloat = 250

    var body: some View {
        VStack(spacing: 40) {
            Spacer().frame(height: 5)
            
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
        } // end VStack
    }
}
