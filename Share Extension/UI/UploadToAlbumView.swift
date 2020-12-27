//
//  UploadToAlbumView.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import Foundation
import SwiftUI
import iOSSignIn

struct UploadToAlbumView: View {
    @ObservedObject var viewModel:ShareViewModel
    
    var body: some View {
        VStack {
            // Using an HStack to get left alignment on the text-- haven't been able to get it left aligned otherwise.
            HStack {
                Text("Upload to:")
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            
            Spacer()
            
            SharingGroupsView(viewModel: viewModel)
        }
    }
}

