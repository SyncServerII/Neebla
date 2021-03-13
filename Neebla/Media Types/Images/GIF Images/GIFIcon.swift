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
            GenericImageIcon(.object(fileLabel: iconFileLabel, object: object), config: config)
                .lowerRightText("gif")
        }
    }
}
