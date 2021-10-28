//
//  ObjectType.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/14/21.
//

import Foundation

// The strings defined here *cannot* be changed easily. They are coded into the running apps via the iOSBasics SyncServer `register` method.

enum ObjectType: String {
    case gif
    case image
    case liveImage
    case url
    case movie
}
