//
//  ObjectDetailsScreenNavButtons.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/15/21.
//

import Foundation
import SwiftUI

struct ObjectDetailsScreenNavButtons: View {
    @Binding var showComments: Bool
    @ObservedObject var model:ObjectDetailsModel
    @StateObject var signInManager = Services.session.signInServices.manager
    @Environment(\.presentationMode) var isPresented

    var body: some View {
        HStack(spacing: 0) {
            // Having both a Button and a Menu (perhaps with sections?) in this tool bar causes some bad looking movement of the items on the toolbar when displayed. But with two menus, you don't get that!

            // TODO: Should create the badge file on demand too-- https://github.com/SyncServerII/Neebla/issues/16
            if model.badgeModel != nil {
                Menu {
                    BadgePickerMenu(model: model)
                } label: {
                    SFSymbolIcon(symbol: .rosette)
                }.enabled(signInManager.userIsSignedIn == true)
            }
            
            Menu {
                Button(
                    action: {
                        showComments = true
                    },
                    label: {
                        HStack {
                            Text("Show comments")
                            SFSymbolIcon(symbol: .message)
                        }
                    }
                )

                Button(
                    action: {
                        model.promptForDeletion(dismiss: {
                            isPresented.wrappedValue.dismiss()
                        })
                    },
                    label: {
                        HStack {
                            Text("Delete media item")
                            SFSymbolIcon(symbol: .trash)
                        }
                    }
                ).enabled(signInManager.userIsSignedIn == true)
            } label: {
                SFSymbolIcon(symbol: .ellipsis)
            }
        }
    }
}
