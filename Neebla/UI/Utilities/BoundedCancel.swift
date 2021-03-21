//
//  BoundedCancel.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/20/21.
//

import Foundation

// Goal: Want to display a spinner for a minimum interval, but no more than a maximum interval.

class BoundedCancel {
    private var cancel:(()->())?
    private var minTimer: Timer!
    private var maxTimer: Timer!
    private var reachedMinimum = false
    private var cancelAtMinimum = false
    
    // `cancel` handler called if max timer expires. 
    init(minInterval: TimeInterval = 1, maxInterval: TimeInterval = 5, cancel: @escaping ()->()) {
        self.cancel = cancel
        
        minTimer = Timer.scheduledTimer(withTimeInterval: minInterval, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            if self.cancelAtMinimum {
                self.maxTimer.invalidate()
                self.doCancel()
            }
            self.reachedMinimum = true
        })
        
        maxTimer = Timer.scheduledTimer(withTimeInterval: maxInterval, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.doCancel()
        })
    }
    
    // If the minimum has not been met, waits until then and cancels. If it has been met, cancels now.
    func minimumCancel() {
        if reachedMinimum {
            doCancel()
        }
        else {
            cancelAtMinimum = true
        }
    }
    
    private func doCancel() {
        cancel?()
        cancel = nil
    }
}
