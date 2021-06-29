//
//  TopView.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/29/21.
//

import Foundation
import SwiftUI

struct TopView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
           content
        }
        .padding([.leading, .top], 10)
        .frame(height: CommentsView.buttonBarHeight)
    }
}
