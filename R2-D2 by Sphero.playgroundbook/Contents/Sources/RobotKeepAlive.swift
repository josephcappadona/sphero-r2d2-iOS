//
//  RobotKeepAliver.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-07-07.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

class RobotKeepAlive {
    
    struct CachedRoll {
        let speed: Double
        let heading: Double
    }

    let queue = OperationQueue()
    var lastRoll = CachedRoll(speed: 0, heading: 0)
    var timer: Timer?
    var toy: AnyToy
    
    public init(toy: AnyToy) {
        self.toy = toy;
    }
    
    func updateLastRoll(speed: Double, heading: Double) {
        lastRoll = CachedRoll(speed: speed, heading: heading)
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] timer in
            guard let weakself = self else { return }
            if weakself.queue.operationCount > 0 {
                weakself.queue.cancelAllOperations()
            }
            
            weakself.queue.addOperation(BlockOperation(block: {
                let speed = weakself.lastRoll.speed
                if speed > 0 {
                    weakself.toy.roll(heading: weakself.lastRoll.heading, speed: speed)
                }
            }))
        })
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        queue.cancelAllOperations()
    }
    
}
