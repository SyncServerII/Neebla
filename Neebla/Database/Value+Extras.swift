
import SQLite
import Foundation
import CoreGraphics

extension CGFloat: Value {
    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    
    public static func fromDatatypeValue(_ blobValue: Blob) -> CGFloat {
        let decoder = JSONDecoder()
        return try! decoder.decode(CGFloat.self, from: Data.fromDatatypeValue(blobValue))
    }
    
    public var datatypeValue: Blob {
        let encoder = JSONEncoder()
        return try! encoder.encode(self).datatypeValue
    }
}
