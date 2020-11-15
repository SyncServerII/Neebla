
import Foundation

extension UUID {
    enum UUIDError: Error {
        case badUUIDString
    }
    
    static func from(_ string: String?) throws -> UUID? {
        if let string = string {
            guard let uuid = UUID(uuidString: string) else {
                throw UUIDError.badUUIDString
            }
            return uuid
        }
        return nil
    }
}
