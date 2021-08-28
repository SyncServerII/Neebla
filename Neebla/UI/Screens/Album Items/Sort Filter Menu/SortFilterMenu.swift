//
//  SortFilterMenu.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/16/21.
//

import Foundation
import SwiftUI
import iOSShared

// Adapted from https://sarunw.com/posts/custom-navigation-bar-title-view-in-swiftui/
// and https://www.simpleswiftguide.com/how-to-make-custom-view-modifiers-in-swiftui/

// Use as a modifier for a NavigationView

extension View {
    func sortyFilterMenu(title: String, sortFilterModel: SortFilterSettings?) -> some View {
        return self.modifier(SortFilterMenu(title: title, sortFilterModel: sortFilterModel))
    }
}

private struct SortFilterMenu: ViewModifier {
    let title: String
    let sortFilterModel: SortFilterSettings?
    
    init(title: String, sortFilterModel: SortFilterSettings?) {
        self.title = title
        self.sortFilterModel = sortFilterModel
    }
    
    func body(content: Content) -> some View {
        return content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SortFilter(title: title, sortFilterModel: sortFilterModel)
                }
            }
    }
}

private struct FilterPickerItem: View {
    let text: String
    let filter: SortFilterSettings.DiscussionFilterBy
    
    var body: some View {
        HStack {
            Text(text)
        }.tag(filter)
    }
}

private struct SortByItem: View {
    let text: String
    let sort: SortFilterSettings.SortBy
    @ObservedObject var model:SortFilterMenuModel
    
    var body: some View {
        HStack {
            Text(text)
            if model.sort == sort {
                SFSymbolIcon(symbol: model.sortOrderChevron)
            }
        }.tag(sort)
    }
}

private struct SortFilter: View {
    @EnvironmentObject var appEnv: AppEnv
    @ObservedObject var model:SortFilterMenuModel
    let title: String
    @State var value: SortFilterSettings.SortBy = .creationDate

    init(title: String, sortFilterModel: SortFilterSettings?) {
        self.title = title
        model = SortFilterMenuModel(sortFilterModel: sortFilterModel)
    }
    
    var body: some View {
        Menu {
            Section {
                Text("Sort By")

                Picker(selection: $model.sort, label: Text("Sort By")) {
                    SortByItem(text: "Creation Date", sort: .creationDate, model: model)
                    SortByItem(text: "Modification Date", sort: .updateDate, model: model)
                }
            }
            
            Section {
                Text("Filter")

                Picker(selection: $model.filter, label: Text("Sort By")) {
                    FilterPickerItem(text: "Show All", filter: .none)
                    FilterPickerItem(text: "Show Only Unread Comments", filter: .onlyUnread)
                    FilterPickerItem(text: "Show Only New Items", filter: .onlyNew)
                    FilterPickerItem(text: "Show New Items or Unread Comments", filter: .newOrUnread)
                }
            }
        } label: {
            HStack {
                // This is the title of the nav bar!
                Text(title)
                    // The cumbersome use of width/maxWidth below is for iPhones. Not resizing title well when switching from portrait to landscape if I use only `maxWidth`.
                    .if(appEnv.isLandScape) {
                        $0.frame(width: maxTextWidth(landScape: true))
                    }
                    .if(!appEnv.isLandScape) {
                        $0.frame(maxWidth: maxTextWidth(landScape: false))
                    }
                    // So that the user can visually discriminate, from the title, whether or not all media items are displayed.
                    .if(model.filtersEnabled) {
                        $0.foregroundColor(Color.gray)
                    }
            }
        }
    }
    
    let titleProportion: CGFloat = 0.4
    
    // A bit of a hack but given the custom view I'm using for the title, I don't have a better way to do this right now.
    func maxTextWidth(landScape: Bool) -> CGFloat {
        let width: CGFloat
        if landScape {
            width = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        }
        else {
            width = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        }
        
        return width * titleProportion
    }
}

