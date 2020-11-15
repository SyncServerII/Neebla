//
//  ItemPreview.swift
//  Share
//
//  Created by Christopher G Prince on 10/6/20.
//

import Foundation
import SwiftUI

struct ItemPreview: View {
    @ObservedObject var viewModel:ViewModel

    var body: some View {
        if let sharingItem = viewModel.sharingItem {
            sharingItem.preview
        }
        else {
            Rectangle()
                .background(Color(UIColor.systemFill))
        }
    }
}

struct ItemPreview_Previews: PreviewProvider {
    static let viewModel = ViewModel()
    static var previews: some View {
        ItemPreview(viewModel: viewModel)
    }
}

