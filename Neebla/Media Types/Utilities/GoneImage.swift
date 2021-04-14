//
//  GoneImage.swift
//  Neebla
//
//  Created by Christopher G Prince on 4/4/21.
//

import Foundation
import SwiftUI

struct GoneImage: View {
    var body: some View {
        Image("Gone")
            .resizable()
            // Initially, "Gone" was black and white. When I switched it to color, and kept the `renderingMode`, the resizing doesn't work.
            // .renderingMode(.template)
    }
}
