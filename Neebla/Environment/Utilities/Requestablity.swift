//
//  Requestablity.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/21/21.
//

import Foundation
import Combine
import Hyperconnectivity
import iOSShared

// Could go back to using Connectivity. See https://github.com/rwbutler/Connectivity/issues/57

class Requestablity: ObservableObject, NetworkRequestable {
    var canMakeNetworkRequests: Bool {
        return isReachable && AppState.session.current == .foreground
    }
    
    func canMakeNetworkRequests(options:NetworkRequestableOptions) -> Bool {
        var result = true
        
        if options.contains(.app) {
            result = result && AppState.session.current == .foreground
        }
        
        if options.contains(.network) {
            result = result && isReachable
        }
        
        return result
    }
    
    private var networkReachabilityObserver: AnyCancellable!
    
    // Using a default value of `true`: Hope for the best. This is related to detecting network connectivity in the sharing extension when it first starts. https://github.com/rwbutler/Hyperconnectivity/issues/1
    private var isReachable: Bool = true
    
    init() {        
        networkReachabilityObserver = Hyperconnectivity.Publisher()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink(receiveValue: { [weak self] connectivityResult in
                // I'm not going to change the reachabilty state when the app is in the background, if that does happen. I've been having problems with false detections of a lack of network when the app comes into the foreground.
                guard AppState.session.current == .foreground else {
                    return
                }
                
                self?.isReachable = connectivityResult.isConnected
                logger.debug("isReachable: \(String(describing: self?.isReachable))")
            })
    }
}
