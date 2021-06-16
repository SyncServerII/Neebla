//
//  MediaItemBadgeView.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/15/21.
//

import Foundation
import SwiftUI

struct MediaItemBadgeView: View {
    let imageName: String
    let size: CGSize
    
    var body: some View {
        Image(imageName)
            .resizable()
            .imageScale(.large)
            .frame(width: size.width, height: size.height)
    }
}

extension MediaItemBadgeView {
    static func getView(badgeModel: ServerFileModel?, size: CGSize) -> AnyView? {
        if let badge = badgeModel?.badge {
            if let imageName = badge.imageName {
                return AnyView(MediaItemBadgeView(imageName: imageName, size: size))
            }
        }
        return nil
    }
}
