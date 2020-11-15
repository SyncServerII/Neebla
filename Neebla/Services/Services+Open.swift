//
//  Services+Open.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/3/20.
//

import Foundation
import UIKit

extension Services {
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return signInServices.manager.application(UIApplication.shared, open: url) ||
            signInServices.sharingInvitation.application(UIApplication.shared, open: url)
    }
}
