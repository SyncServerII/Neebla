//
//  ItemPreview.swift
//  Share
//
//  Created by Christopher G Prince on 10/6/20.
//

import Foundation
import SwiftUI

struct ItemPreview: View {
    @ObservedObject var viewModel:ShareViewModel
    let iconConfig: IconConfig
    
    var body: some View {
        if let sharingItem = viewModel.sharingItem {
            sharingItem.preview(for: iconConfig)
        }
        else {
            Rectangle()
                .fill(Color.clear)
                .border(Color(UIColor.systemFill))
        }
    }
}


