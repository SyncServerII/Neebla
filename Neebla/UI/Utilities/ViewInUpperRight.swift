//
//  ViewInUpperRight.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/30/20.
//

import Foundation
import SwiftUI

struct ViewInUpperRight<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                content
                    .foregroundColor(Color.black)
                    // To get leading & trailing white-colored space
                    .padding([.leading, .trailing], 5)
                    .background(Color.white.opacity(0.7))
                    // To get leading & trailing clear space
                    .padding([.trailing, .top], 4)
            }
            Spacer()
        }
    }
}
