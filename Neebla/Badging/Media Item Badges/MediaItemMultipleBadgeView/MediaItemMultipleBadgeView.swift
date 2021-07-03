//
//  MediaItemMultipleBadgeView.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/25/21.
//

import Foundation
import SwiftUI

struct MediaItemMultipleBadgeView: View {
    @ObservedObject var model:MediaItemMultipleBadgeViewModel
    let size: CGSize // size of each badge view
    
    init(object: ServerObjectModel, maxNumberOthersBadges: Int, size: CGSize) {
        model = MediaItemMultipleBadgeViewModel(object: object, maxNumberOthersBadges: maxNumberOthersBadges)
        self.size = size
    }
    
    var body: some View {
        VStack {
            // Not showing a .hide badge because we show a special image for this. And because it seems a little confusing to have both the special image and a hide badge.
            if let badges = model.mediaItemBadges, badges.selfBadge != .hide {
                if let selfBadge = model.mediaItemBadges?.selfBadge {
                    MediaItemSingleBadgeView(badge: selfBadge, size: size)
                }
                
                if badges.othersBadges.count > 0 {
                    VStack(spacing: 0) {
                        Text("Others")
                            .foregroundColor(Color(UIColor.darkGray))
                            .font(Font.system(size: 14))
                            
                        // If there is no self-badge, the gray border around these (if any) should make it clear that they are not self badges.
                        ForEach(badges.othersBadges, id: \.userId) { userBadge in
                            MediaItemSingleBadgeView(badge: userBadge.badge, size: size)
                        }
                    }
                    .padding(5)
                    .border(Color.gray, width: 2)
                }
            }
        }
    }
}
