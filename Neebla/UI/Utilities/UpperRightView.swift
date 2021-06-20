//
//  UpperRightView.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/21/21.
//

import Foundation
import SwiftUI

extension View {
    func upperRightView<V: View>(@ViewBuilder _ view: @escaping () -> V) -> some View {
        return self.modifier(UpperRightView(view))
    }
}

struct UpperRightView<V>: ViewModifier where V: View {
    let view: () -> V
    init(@ViewBuilder _ view: @escaping () -> V) {
        self.view = view
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    view()
                }
                .padding([.top, .trailing], 5),
                alignment: .topTrailing
            )
    }
}
