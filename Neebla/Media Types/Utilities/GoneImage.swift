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
            .renderingMode(.template)
            .foregroundColor(.red)
    }
}
