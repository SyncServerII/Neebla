//
//  ViewModel.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import Foundation
import SwiftUI
import iOSSignIn
import ServerShared

struct SharingGroupData: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

class ViewModel: ObservableObject {
    @Published var width: CGFloat = 0
    @Published var height: CGFloat = 0
    @Published var sharingGroups = [SharingGroupData]()
    @Published var userSignedIn: Bool = true
    @Published var selectedSharingGroupUUID: UUID?
    @Published var sharingItem: ItemProvider?
    var cancel:(()->())?
    var post:((ItemProvider, _ sharingGroupUUID: UUID)->())!
}
