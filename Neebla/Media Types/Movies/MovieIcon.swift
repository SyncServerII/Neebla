//
//  MovieIcon.swift
//  Neebla
//
//  Created by Christopher G Prince on 10/26/21.
//

import Foundation
import SwiftUI

struct MovieIcon: View {
    @ObservedObject var model: GenericImageModel
    let config: IconConfig
    
    init(object: ServerObjectModel, config: IconConfig) {
        model = GenericImageModel(fileLabel: MovieObjectType.imageDeclaration.fileLabel, fileGroupUUID: object.fileGroupUUID, imageScale: config.iconSize)
        self.config = config
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(model: model, config: config)
                .lowerRightText("movie")
        }
    }
}
