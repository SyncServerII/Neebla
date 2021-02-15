//
//  LowerRightText.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/21/21.
//

import Foundation
import SwiftUI

extension View {
    func lowerRightText(_ text: String) -> some View {
        return self.modifier(LowerRightText(text))
    }
}

struct LowerRightText: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let text: String
    
    init(_ text: String) {
        self.text = text
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    Text(text)
                        // Foreground color is fine by default in light mode.
                        .if (colorScheme == .dark) {
                            $0.foregroundColor(Color(UIColor.black))
                        }
                        .padding([.top, .bottom], 2)
                        .padding([.leading, .trailing], 5)
                        .background(Color.white.opacity(0.7))
                }
                .padding([.trailing, .bottom], 5),
                alignment: .bottomTrailing
            )
    }
}
