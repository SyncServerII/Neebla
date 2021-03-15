//
//  HTMLViewer.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/14/21.
//

import Foundation
import SwiftUI
import WebKit

struct HTMLViewer: View {
    let html: String
    
    var body: some View {        
        HTMLStringView(htmlContent: html)
            // This is needed or the text doesn't get shown.
            // See https://developer.apple.com/forums/thread/653935 and
            // https://stackoverflow.com/questions/56892691
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, idealHeight: 500, maxHeight: .infinity, alignment: .center)
    }
}

private struct HTMLStringView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
