
// These services are specific to the Neebla app, and not also used with the sharing extension.

import Foundation

class LocalServices {
    // You must call `setup`, and it must not fail, prior to using this.
    static var session:LocalServices!
    
    let previewGenerator:URLPreviewGenerator
    
    init() throws {
        previewGenerator = try URLPreviewGenerator()
        try AnyTypeManager.session.setup()
    }
    
    static func setup() throws {
        session = try LocalServices()
    }
}
