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
    
    static let providers:[SXItemProvider.Type] = SXAllItemProviders.providers
    
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
