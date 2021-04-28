//
//  DetectV1.swift
//  Neebla
//
//  Created by Christopher G Prince on 4/27/21.
//

import Foundation
import iOSShared

class DetectV1 {
    // From the v1 app.
    let v1UserDefaultsKey = "Migrations.v0_18_3"
    /*
    private static let v0_18_3 = SMPersistItemBool(name: "Migrations.v0_18_3", initialBoolValue: false, persistType: .userDefaults)
    */
    
    static let session = DetectV1()
    
    private(set) var isV1: Bool = false
    
    private init() {
        let object = UserDefaults.standard.object(forKey: v1UserDefaultsKey)
        logger.debug("v1UserDefaultsKey: \(String(describing: object))")
        isV1 = object != nil
    }
}
