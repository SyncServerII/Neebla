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
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .padding([.leading, .trailing], 10)
            .padding([.top, .bottom], 4)
            .background(Color.red)
            .cornerRadius(20)
            .foregroundColor(.white)
            .font(Font.system(size: 14))
    }
}
