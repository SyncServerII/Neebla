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
    @ObservedObject var viewModel:ViewModel
    @Environment(\.colorScheme) var colorScheme

    var selectedColor: Color {
        if colorScheme == .dark {
            return Color(red: 0, green: 0, blue: 114, opacity: 1.0)
        }
        else {
            return Color(red: 0, green: 140, blue: 230, opacity: 1.0)
        }
    }
    
    var body: some View {
        // Wanted to use a form to get the list background color working, but this makes the header non-sticky https://stackoverflow.com/questions/56517904
        List {
            Section(header: Text("Album")) {
                ForEach(viewModel.sharingGroups, id: \.self) { group in
                    Button(action: {
                        self.viewModel.selectedSharingGroupUUID = group.id
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

struct SharingGroups_Previews: PreviewProvider {
    static let viewModel = ViewModel()
    static var previews: some View {
        viewModel.width = 150
        viewModel.height = 300
        viewModel.sharingGroups = [SharingGroupData(id: UUID(), name: "Group 1"), SharingGroupData(id: UUID(), name: "Group 2"), SharingGroupData(id: UUID(), name: "Group 3")]
        return SharingGroupsView(viewModel: viewModel)
    }
}

