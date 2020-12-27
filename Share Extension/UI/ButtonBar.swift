//
//  ButtonBar.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import Foundation
import SwiftUI
import iOSSignIn

struct ButtonBar: View {
    @ObservedObject var viewModel:ShareViewModel
    
    var body: some View {
        ZStack {
            Text("Neebla")
                .font(.title)
            
            HStack {
                Button("Cancel", action: {
                    viewModel.cancel?()
                })
                
                Spacer()
                
                Button("Post", action: {
                    if let preview = viewModel.sharingItem,
                        let sharingGroupUUID = viewModel.selectedSharingGroupUUID {
                        viewModel.upload(item: preview, sharingGroupUUID: sharingGroupUUID)
                    }
                })
                .disabled(viewModel.sharingItem == nil || viewModel.selectedSharingGroupUUID == nil)
            }
        }
        .frame(height: 50)
    }
}


