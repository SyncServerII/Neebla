//
//  ItemProviderFactory.swift
//  Share
//
//  Created by Christopher G Prince on 10/6/20.
//

import Foundation

class ItemProviderFactory {
    var handle: Any?
    
    enum ItemProviderFactoryError: Error {
        case noMatchingTypeIdentifiers
        case couldNotGetURL
    }
    
    // The order in this list matters. If one provider works, the following are not tried.
    static let providers:[SXItemProvider.Type] = [
        // Try this first. If we put `ImageItemProvider` first and the image available is JPEG, it will succeed and the live image will never succeed.
        LiveImageItemProvider.self,

        ImageItemProvider.self,
        URLItemProvider.self,
        GIFItemProvider.self
    ]
    
    func create(using attachment: NSItemProvider, completion: @escaping (Result<SXItemProvider, Error>)->()) throws {
        
        for provider in Self.providers {
            if provider.canHandle(item: attachment) {
                handle = provider.create(item: attachment, completion: completion)
                return
            }
        }
        
        throw ItemProviderFactoryError.noMatchingTypeIdentifiers
    }
}
