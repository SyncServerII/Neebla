//
//  ViewInUpperLeft.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/2/21.
//

import Foundation
import SwiftUI

struct ViewInUpperLeft<Content: View>: View {
    let content: Content
    let topPadding: CGFloat?
    
    init(topPadding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.topPadding = topPadding
    }
    
    var body: some View {
        VStack {
            if let topPadding = topPadding {
                Spacer().frame(height: topPadding)
            }
            HStack {
                content
                    .padding([.leading], 5)
                Spacer()
            }
            Spacer()
        }
    }
}
