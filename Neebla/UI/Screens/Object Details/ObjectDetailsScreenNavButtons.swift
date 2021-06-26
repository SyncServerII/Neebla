//
//  ObjectDetailsScreenNavButtons.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/15/21.
//

import Foundation
import SwiftUI

struct ObjectDetailsScreenNavButtons: View {
    @ObservedObject var model:ObjectDetailsModel
    let tapBadgePickerMenu:()->()
    @StateObject var signInManager = Services.session.signInServices.manager
    @Environment(\.presentationMode) var isPresented

    var body: some View {
        HStack(spacing: 0) {
            // Having both a Button and a Menu (perhaps with sections?) in this tool bar causes some bad looking movement of the items on the toolbar when displayed. But with two menus, you don't get that!

            if model.badgeModel != nil {
                Menu {
                    BadgePickerMenu(model: model)
                } label: {
                    SFSymbolIcon(symbol: .rosette)
                }.enabled(signInManager.userIsSignedIn == true)
                .onTapGesture {
                    tapBadgePickerMenu()
                }
            }
            
            Menu {
                Button(
                    action: {
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
                            // Dismiss the screen on which the menu is presented.
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
