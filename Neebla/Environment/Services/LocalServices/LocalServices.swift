
// These services are specific to the Neebla app, and not also used with the sharing extension.

import Foundation
import SQLite

class LocalServices {
    // You must call `setup`, and it must not fail, prior to using this.
    static var session:LocalServices!
    
    let previewGenerator:URLPreviewGenerator
    var initialized = false
    
    init() throws {
        previewGenerator = try URLPreviewGenerator()
    }
    
    static func setup(db: Connection) throws {
        session = try LocalServices()
        try SetupLocalDatabase.setup(db: db)
        session.initialized = true
    }
}
