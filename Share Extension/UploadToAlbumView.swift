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
    @ObservedObject var viewModel:ViewModel
    
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

struct UploadToAlbumView_Previews: PreviewProvider {
    static let viewModel = ViewModel()
    static var previews: some View {
        viewModel.width = 250
        viewModel.height = 400
        viewModel.sharingGroups = [SharingGroupData(id: UUID(), name: "Group 1"), SharingGroupData(id: UUID(), name: "Group 2"), SharingGroupData(id: UUID(), name: "Group 3")]
        return UploadToAlbumView(viewModel: viewModel)
    }
}
