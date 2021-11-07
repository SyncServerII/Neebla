//
//  UpperLeftBadge.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/21/21.
//

import Foundation
import SwiftUI

extension View {
    func upperLeftBadge(_ badgeText: String?) -> some View {
        return self.modifier(UpperLeftBadge(badgeText: badgeText))
    }
}

struct UpperLeftBadge: ViewModifier {
    let badgeText: String?

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let badgeText = badgeText {
                        Badge(badgeText)
                    }
                }
                .padding([.top, .leading], 5),
                alignment: .topLeading
            )
    }
}
