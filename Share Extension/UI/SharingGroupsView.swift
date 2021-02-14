//
//  SharingGroups.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import SwiftUI
import iOSSignIn

// Adapted from https://stackoverflow.com/questions/59141688/swiftui-change-list-row-highlight-colour-when-tapped

struct SharingGroupsView: View {
    @ObservedObject var viewModel:ShareViewModel
    @Environment(\.colorScheme) var colorScheme

    var selectedColor: Color {
        if colorScheme == .dark {
            return Color.gray
        }
        else {
            return Color(UIColor.lightGray)
        }
    }
    
    var body: some View {
        // Wanted to use a form to get the list background color working, but this makes the header non-sticky https://stackoverflow.com/questions/56517904
        List {
            Section(header: Text("Album")) {
                ForEach(viewModel.sharingGroups, id: \.self) { group in
                    Button(action: {
                        if self.viewModel.selectedSharingGroupUUID != group.id {
                            self.viewModel.selectedSharingGroupUUID = group.id
                        }
                    }, label: {
                        Text(group.name)
                    })
                    .listRowBackground(
                        self.viewModel.selectedSharingGroupUUID == group.id ?
                        selectedColor :
                        Color(UIColor.systemGroupedBackground))
                }
            // `textCase` -- a hack to not have the Section title be upper case. See https://developer.apple.com/forums/thread/655524
            }.textCase(nil)
        }.listRowBackground(Color(UIColor.systemBackground))
        .background(Color(UIColor.systemBackground))
    }
}


