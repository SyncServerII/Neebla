//
//  Badge.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/2/21.
//

import Foundation
import SwiftUI

struct Badge: View {
    let text: String
    let backgroundColor: Color
    
    init(_ text: String, backgroundColor: Color = .red) {
        self.text = text
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Text(text)
            .padding([.leading, .trailing], 10)
            .padding([.top, .bottom], 4)
            .background(backgroundColor)
            .cornerRadius(20)
            .foregroundColor(.white)
            .font(Font.system(size: 14))
    }
}

struct BadgeOverlay: View {
    let text: String
    
    var body: some View {
        ZStack {
            Badge(text)
        }
    }
}
