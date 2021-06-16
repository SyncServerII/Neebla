//
//  AlbumItemsScreenCellModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/15/21.
//

import Foundation
import SwiftUI

class AlbumItemsScreenCellModel: ObservableObject {
    @Published var badgeView: AnyView?

    init(object:ServerObjectModel) {
        let badgeModel = try? ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
        badgeView = MediaItemBadgeView.getView(badgeModel: badgeModel, size: CGSize(width: 20, height: 20))
    }
}
