//
//  KeywordsBadgeView.swift
//  Neebla
//
//  Created by Christopher G Prince on 7/2/21.
//

import Foundation
import SwiftUI

struct KeywordsBadgeView: View {
    let object: ServerObjectModel
    let size: CGSize
    let tap:()->()
    
    var body: some View {
        if let keywords = object.keywords, keywords.count > 0 {
            Image("Keyword.icon")
                .resizable()
                .imageScale(.large)
                .frame(width: size.width, height: size.height)
                .onTapGesture {
                    tap()
                }
        }
    }
}
