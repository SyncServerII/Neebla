//
//  Services+SignInServicesHelper.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/31/20.
//

import Foundation
import iOSSignIn
import ServerShared
import iOSShared

extension Services: iOSSignIn.SignInServicesHelper {
    public func signUserOut() {
        logger.error("signUserOut: SignInServicesHelper")
        signInServices.manager.currentSignIn?.signUserOut()
    }
    
    public var currentCredentials: GenericCredentials? {
        return signInServices.manager.currentSignIn?.credentials
    }
    
    public var cloudStorageType: CloudStorageType? {
        return signInServices.manager.currentSignIn?.cloudStorageType
    }
    
    public var userType: UserType? {
        return signInServices.manager.currentSignIn?.userType
    }
}
