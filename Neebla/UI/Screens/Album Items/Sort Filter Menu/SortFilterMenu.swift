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

// Embed in a NavigationView

extension View {
    func sortyFilterMenu(title: String) -> some View {
        return self.modifier(SortFilterMenu(title: title))
    }
}

private struct SortFilterMenu: ViewModifier {
    let title: String
    
    init(title: String) {
        self.title = title
    }
    
    func body(content: Content) -> some View {
        return content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SortFilter(title: title)
                }
            }
    }
}

private struct SortFilter: View {
    @EnvironmentObject var appEnv: AppEnv

    enum Filter: Hashable {
        case all
        case onlyUnread
    }
    
    @State var filter: Int = 0
    let title: String
    
    init(title: String) {
        self.title = title
    }
    
    var body: some View {
        Menu {
            Section {
                Text("Sort").bold()

                Button(action: {
                }) {
                    HStack {
                        Text("Date")
                        SFSymbolIcon(symbol: .chevronUp)
                    }
                }
            }
            
            Section {
                Text("Filter").bold()

                Button(action: {
                }) {
                    HStack {
                        Text("All")
                        SFSymbolIcon(symbol: .square)
                    }
                }

                Button(action: {
                }) {
                    HStack {
                        Text("Only Unread")
                        SFSymbolIcon(symbol: .squareFill)
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

