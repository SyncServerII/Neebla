//
//  UpperRightView.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/21/21.
//

import Foundation
import SwiftUI

extension View {
    func upperRightView(_ view: AnyView) -> some View {
        return self.modifier(UpperRightView(view))
    }
}

struct UpperRightView: ViewModifier {
    let view: AnyView
    init(_ view: AnyView) {
        self.view = view
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    view
                }
                .padding([.top, .trailing], 5),
                alignment: .topTrailing
            )
    }
}
