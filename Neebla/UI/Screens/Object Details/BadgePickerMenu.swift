//
//  BadgePickerMenu.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/14/21.
//

import Foundation
import SwiftUI

struct BadgePickerMenu: View {
    @ObservedObject var model:ObjectDetailsModel
    
    var body: some View {
        Section {
            Text("Select Badge")
            
            ForEach(MediaItemBadge.allCases, id: \.self) { badge in
                Button(action: {
                    try? model.selectBadge(newBadgeSelection: badge)
                }) {
                    HStack {
                        Text(badge.displayName)
                        SFSymbolIcon(symbol:
                            model.badgeSelected == badge ? .circleFill : .circle)
                    }
                }
            }
        }
    }
}
