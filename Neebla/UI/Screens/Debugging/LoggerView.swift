//
//  LoggerView.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/3/20.
//

import Foundation
import SwiftUI
import MobileCoreServices

struct LoggerView: View {
    @State private var loggerText: String?

    var body: some View {        
        return MenuNavBar(title: "Logger Text") {
            VStack {
                TextEditor(text: $loggerText ?? "")
                    .foregroundColor(Color(UIColor.label))
                    .border(Color(UIColor.label))
                    .padding(10)
                    
                Button(action: {
                    loggerText = Services.session.currentLogFileContents
                }) {
                    Text("Refresh")
                }
            }
        }
    }
}
