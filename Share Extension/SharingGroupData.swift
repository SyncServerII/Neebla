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

