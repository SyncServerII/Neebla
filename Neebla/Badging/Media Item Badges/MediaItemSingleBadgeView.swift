//
//  MediaItemBadgeView.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/15/21.
//

import Foundation
import SwiftUI

struct MediaItemSingleBadgeView: View {
    let badge: MediaItemBadge?
    let size: CGSize
    
    var body: some View {
        if let imageName = badge?.imageName {
            Image(imageName)
                .resizable()
                .imageScale(.large)
                .frame(width: size.width, height: size.height)
            }
        else {
            EmptyView()
        }
    }
}
