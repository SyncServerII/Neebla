//
//  LowerLeftIcon.swift
//  Neebla
//
//  Created by Christopher G Prince on 8/26/21.
//

import Foundation
import SwiftUI

extension View {
    func lowerLeftIcon(_ name: String) -> some View {
        return self.modifier(LowerLeftIcon(name: name))
    }
}

struct LowerLeftIcon: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    Image(name)
                }
                .padding([.trailing, .bottom], 0),
                    alignment: .bottomLeading
            )
    }
}
