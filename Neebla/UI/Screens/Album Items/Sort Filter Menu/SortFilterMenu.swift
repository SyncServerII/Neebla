//
//  SortFilterMenu.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/16/21.
//

import Foundation
import SwiftUI

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

private struct SortFilter: View {
    @EnvironmentObject var appEnv: AppEnv
    @ObservedObject var model:SortFilterMenuModel
    let title: String
    
    init(title: String, sortFilterModel: SortFilterSettings?) {
        self.title = title
        model = SortFilterMenuModel(sortFilterModel: sortFilterModel)
    }
    
    var body: some View {
        Menu {
            Section {
                Text("Sort By")

                // Getting no animation here: https://stackoverflow.com/questions/65766781
                Button(action: {
                    model.toggleSortOrder()
                }) {
                    HStack {
                        Text("Creation Date")
                        SFSymbolIcon(symbol: model.sortOrderChevron)
                    }
                }
            }
            
            Section {
                Text("Discussion Filter")

                Button(action: {
                    model.select(filter: .none)
                }) {
                    HStack {
                        Text("Show All")
                        SFSymbolIcon(symbol: model.showAllIcon)
                    }
                }

                Button(action: {
                    model.select(filter: .onlyUnread)
                }) {
                    HStack {
                        Text("Show Only Unread")
                        SFSymbolIcon(symbol: model.showOnlyUnreadIcon)
                    }
                }
            }
        } label: {
            HStack {
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

