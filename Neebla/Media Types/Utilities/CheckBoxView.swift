//
//  CheckBoxView.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/13/21.
//

import Foundation
import SwiftUI

// Modified from https://stackoverflow.com/questions/58425829
struct CheckBoxView: View {
    @Binding var checked: Bool
    var text: String
    
    var body: some View {
        Button(
            action: {
                self.checked.toggle()
            },
            label: {
                HStack {
                    Image(systemName: checked ? "checkmark.square.fill" : "square")
                        .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
                    Text(text)
                }
            }
        )
    }
}

