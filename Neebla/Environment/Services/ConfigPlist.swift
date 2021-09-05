//
//  ConfigKeys.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/20/20.
//

import Foundation

enum ConfigKey: String {
    case serverURL
    case DropboxAppKey
    case GoogleClientId
    case GoogleServerClientId
    case cloudFolderName
    case failoverMessageURL
}

class ConfigPlist {
    let configPlist:Dictionary<String, Any>
    
    init?(filePath: String) {
        guard let configPlist = NSDictionary(contentsOfFile: filePath) as? Dictionary<String, Any> else {
            return nil
        }
        
        self.configPlist = configPlist
    }
    
    func getValue(for key: ConfigKey) -> String? {
        return configPlist[key.rawValue] as? String
    }
}
