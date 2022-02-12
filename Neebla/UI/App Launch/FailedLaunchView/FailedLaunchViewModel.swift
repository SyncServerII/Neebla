//
//  FailedLaunchViewModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/12/22.
//

import Foundation
import MessageUI

class FailedLaunchViewModel: ObservableObject {
    @Published var sendMailResult: Swift.Result<MFMailComposeResult, Error>? = nil
}

extension FailedLaunchViewModel: AddEmailAttachments {
    func addAttachments(vc: MFMailComposeViewController) {
        EmailDeveloper.addLogs(vc: vc)
    }
}

