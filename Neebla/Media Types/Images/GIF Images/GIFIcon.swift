//
//  GIFIcon.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/11/21.
//

import Foundation
import SwiftUI

struct GIFIcon: View {
    let iconFileLabel = GIFObjectType.iconDeclaration.fileLabel
    let object: ServerObjectModel
    let config: IconConfig
    
    init(object: ServerObjectModel, config: IconConfig) {
        self.object = object
        self.config = config
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(model:
                GenericImageIcon.setupModel(.object(fileLabel: iconFileLabel, object: object), iconSize: config.iconSize),
                    config: config)
                .lowerRightText("gif")
        }
    }
}
