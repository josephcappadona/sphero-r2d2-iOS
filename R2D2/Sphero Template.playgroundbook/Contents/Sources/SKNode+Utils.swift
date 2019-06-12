//
//  SKPhysicsBody+Utils.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-28.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public extension SKNode {
    public func rotate(towards angle: CGFloat, maxSpeed: CGFloat) {
        guard let body = physicsBody else { return }
        
        var angleDiff = (angle - zRotation).truncatingRemainder(dividingBy: 2 * CGFloat.pi)
        
        if angleDiff < -CGFloat.pi {
            angleDiff += 2 * CGFloat.pi
        } else if angleDiff > CGFloat.pi {
            angleDiff -= 2 * CGFloat.pi
        }
        
        let angularVelocityMagnitude = min(maxSpeed, 20.0 * abs(angleDiff))
        
        body.angularVelocity = copysign(angularVelocityMagnitude, angleDiff)
    }
}
