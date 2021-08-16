//
//  FailedLaunchView.swift
//  Neebla
//
//  Created by Christopher G Prince on 8/9/21.
//

import Foundation
import SwiftUI

struct FailedLaunchView : View {
    var body: some View {
        VStack {
            Text("Neebla has failed to launch.")
                .font(.largeTitle)
            Text("Please contact the developer.")
        }
    }
}
