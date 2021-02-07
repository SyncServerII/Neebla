//
//  EmailContents.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/31/20.
//

import Foundation
import MessageUI

protocol AddEmailAttachments {
    func addAttachments(vc: MFMailComposeViewController)
}

struct EmailContents {
    let subject: String
    let body: String?
    let to: String?
    
    init(subject: String, body: String? = nil, to: String? = nil) {
        self.subject = subject
        self.body = body
        self.to = to
    }
}
