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

class Requestablity: ObservableObject, NetworkRequestable {
    var canMakeNetworkRequests: Bool {
        return isReachable && AppState.session.current == .foreground
    }
    
    private var networkReachabilityObserver: AnyCancellable!
    
    // Using a default value of `true`: Hope for the best. This is related to detecting network connectivity in the sharing extension when it first starts. https://github.com/rwbutler/Hyperconnectivity/issues/1
    private var isReachable: Bool = true
    
    init() {        
        networkReachabilityObserver = Hyperconnectivity.Publisher()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink(receiveValue: { [weak self] connectivityResult in
                self?.isReachable = connectivityResult.isConnected
                logger.debug("isReachable: \(String(describing: self?.isReachable))")
            })
    }
}
