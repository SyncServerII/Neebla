//
//  RemoveUserSheet.swift
//  Neebla
//
//  Created by Christopher G Prince on 4/17/21.
//

import Foundation
import SwiftUI
import iOSShared

struct RemoveUserSheet: View {
    @Environment(\.presentationMode) var isPresented
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Button(action: {
                        self.isPresented.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }.padding(.leading, 10)
                    
                    Spacer()
                }
                
                Text("Remove User")
                    .font(.title)
                    .foregroundColor(Color.red)
                    .padding(.top, 10)
            }

            ScrollView {
                VStack(spacing: 20) {
                    Text("This will remove you from the Neebla server.")
                    
                    Text("You will still own media you added, if you have cloud storage -- in your own cloud storage (e.g., Dropbox or Google Drive).")
                    
                    Text("But you will no longer be able to sign into Neebla.")
                    Text("You will no longer be able to upload media, nor share them with others using Neebla.")
                    Text("You will no longer be able to download media, shared by others using Neebla.")
                    
                    Text("Other users will also not be able to access media that you previously had shared.")
                    
                    Text("Should you decide to later again add an account on Neebla, you will be starting from scratch. You would have to manually re-upload any media and comments that you made before, if that is wanted.")
                    
                    Spacer()
                    
                    Button(action: {
                        showAlert(removeUserConfirmation {
                            Services.session.serverInterface.signIns.removeUser { error in
                                if let error = error {
                                    logger.error("\(error)")
                                    showAlert(AlertyHelper.alert(title: "Alert!", message: "An error occured while trying to remove user."))
                                    return
                                }
                                
                                showAlert(confirmAlert(title: "Success", message: "You have been removed from Neebla", actionButtonTitle: "OK", action: {
                                    self.isPresented.wrappedValue.dismiss()
                                }))
                            }
                        })
                    }) {
                        Text("Remove Yourself")
                    }
                }
                .padding(20)
                .font(.system(size: 25))
                .multilineTextAlignment(.center)
            }
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
    }
    
    func removeUserConfirmation(action: @escaping ()->()) -> SwiftUI.Alert {
        let cancel = SwiftUI.Alert.Button.cancel(Text("Cancel")) {
            self.isPresented.wrappedValue.dismiss()
        }

        let removeButton = SwiftUI.Alert.Button.destructive(
            Text("Remove User"),
            action: {
                action()
            }
        )
        return SwiftUI.Alert(title: Text("Warning!"),
            message:
                Text("Confirm that you want to remove yourself."),
            primaryButton: removeButton,
            secondaryButton: cancel)
    }
    
    func confirmAlert(title: String, message: String, actionButtonTitle: String, action: @escaping ()->()) -> SwiftUI.Alert {
        let defaultButton = SwiftUI.Alert.Button.default(
            Text(actionButtonTitle),
            action: {
                action()
            }
        )
        
        return SwiftUI.Alert(title: Text(title), message: Text(message), dismissButton: defaultButton)
    }
}

