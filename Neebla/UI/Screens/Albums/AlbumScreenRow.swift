//
//  AlbumScreenRow.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import SwiftUI
import SFSafeSymbols
import iOSSignIn
import iOSShared

struct AlbumsScreenRow: View {
    @StateObject var viewModel:AlbumsViewModel
    @StateObject var rowModel:AlbumScreenRowModel
    @Binding var album: AlbumModel
    @Environment(\.colorScheme) var colorScheme
    @StateObject var signInManager = Services.session.signInServices.manager
    
    var body: some View {
        HStack {
            if let albumName = album.albumName {
                Text(albumName)
            }
            else {
                Text(AlbumModel.untitledAlbumName)
            }

            Spacer()
            
            if let newCountText = rowModel.albumNewCountBadgeText {
                Badge(newCountText, backgroundColor: .blue)
            }
            
            if let badgeText = rowModel.albumUnreadCountBadgeText {
                Badge(badgeText)
            }
            
            // Indicate whether or not there are updates available to download for this album.
            if rowModel.albumNeedsDownload {
                Icon(imageName:
                    "Download.White",
                    size: CGSize(width: 25, height: 25), blueAccent: false)
                    .accentColor(colorScheme == .light ? .black : .white)
            }
            
            // To change an album name and to share an album, you must have .admin permissions.
            if album.permission.hasMinimumPermission(.admin) {
                if viewModel.sharingMode {
                    Icon(imageName:
                        Images.shareIcon(lightMode:colorScheme == .light),
                        size: CGSize(width: 25, height: 25))
                }
                else {
                    Button(action: {
                        viewModel.startChangeExistingAlbumName(sharingGroupUUID: album.sharingGroupUUID, currentAlbumName: album.albumName)
                    }, label: {
                        Image(systemName: SFSymbol.pencil.rawValue)
                    }).buttonStyle(PlainButtonStyle())
                    .enabled(signInManager.userIsSignedIn == true)
                }
            }

            // I'm using the .buttonStyle above b/c otherwise, I'm not getting the button tap. See https://www.hackingwithswift.com/forums/swiftui/is-it-possible-to-have-a-button-action-in-a-list-foreach-view/1153
            // See also https://stackoverflow.com/questions/56845670
        }
    }
}
