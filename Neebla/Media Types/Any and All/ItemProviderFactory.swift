//
//  ItemProviderFactory.swift
//  Share
//
//  Created by Christopher G Prince on 10/6/20.
//

import Foundation

class ItemProviderFactory {
    enum ItemProviderFactoryError: Error {
        case noMatchingTypeIdentifiers
        case couldNotGetURL
    }
    
    // The order in this list matters. If one provider works, the following are not tried.
    static let providers:[SXItemProvider.Type] = [
        ImageItemProvider.self
    ]
    
    static func create(using attachment: NSItemProvider, completion: @escaping (Result<SXItemProvider, Error>)->()) throws {
        
        for provider in providers {
            if provider.canHandle(item: attachment) {
                provider.create(item: attachment, completion: completion)
                return
            }
        }
        
        throw ItemProviderFactoryError.noMatchingTypeIdentifiers
    }
}
