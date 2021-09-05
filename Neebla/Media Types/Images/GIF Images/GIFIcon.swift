//
//  GIFIcon.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/11/21.
//

import Foundation
import SwiftUI

struct GIFIcon: View {
    @ObservedObject var object: ServerObjectModel
    let config: IconConfig
    
    var body: some View {
        ZStack {
            GenericImageIcon(model:
                GenericImageIcon.setupModel(.object(fileLabel: GIFObjectType.iconDeclaration.fileLabel, object: object), iconSize: config.iconSize),
                    config: config)
                .lowerRightText("gif")
        }
    }
}
