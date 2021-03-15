//
//  AboutApp.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/14/21.
//

import Foundation
import SwiftUI

struct AboutApp: View {
    @StateObject var model = AboutAppModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    SFSymbolIcon(symbol: .multiplyCircle)
                })
                .padding(.leading, 10)
                
                Spacer()
            }
            
            Text("About Neebla")
        }
        
        if let html = model.html {
            HTMLViewer(html: html)
        }
        else {
            Text("Could not load about info.")
        }
    }
}
