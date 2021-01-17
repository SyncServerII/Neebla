//
//  UpdateView.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/16/21.
//

import Foundation
import SwiftUI

// Just a means to get some code executed when a View is updated.

extension View {
    func updateView(_ closure: ()->()) -> some View {
        return self.modifier(UpdateView(closure))
    }
}

struct UpdateView: ViewModifier {
     init(_ closure: ()->()) {
         closure()
     }

     func body(content: Content) -> some View {
         content
     }
 }
