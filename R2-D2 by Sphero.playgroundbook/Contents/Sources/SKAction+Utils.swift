//
//  SKActionTimingFunction+Curves.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-05-04.
//  Copyright © 2017 Sphero Inc. Inc. All rights reserved.
//

import SpriteKit

public struct TimingFunctions {
    private init() { }

    static let parabolicEaseOut: SKActionTimingFunction = { (time: Float) in
        return time * (2 - time)
    }
    
    static let parabolicEaseIn: SKActionTimingFunction = { (time: Float) in
        return time * time
    }
    
    static let cubicEaseMiddle: SKActionTimingFunction = { (time: Float) in
        return (pow(2*time-1, 3.0) + 1) / 2.0
    }
    
    static let cubicEaseInOut: SKActionTimingFunction = { (time: Float) in
        return time * time * (3.0 - 2.0 * time)
    }
    
    static let sinusoidalEaseOut = { (time: Float) in
        return sinf(time * Float.pi / 2.0)
    }
    
    static let sinusoidalEaseIn = { (time: Float) in
        return 1.0 + sinf((time - 1.0) * Float.pi / 2.0)
    }
    
    // Parabola from 0 to 1 whose derivative at 0 is startingSpeed.
    // startingSpeed = 0 eases in
    // startingSpeed = 1 is linear
    // startingSpeed = 2 eases out
    static func parabolic(fromSpeed startingSpeed: Float) -> SKActionTimingFunction {
        let a = 1 - startingSpeed
        let b = startingSpeed
        return { (time: Float) in
            return a * time * time + b * time
        }
    }
    
    
    // Cubic which starts and ends at the same speed, and has middleSpeed at time = 0.5
    // middleSpeed = 0 gives cubicEaseMiddle
    // middleSpeed = 1 is linear
    // middleSpeed = 1.5 gives cubicEaseInOut
    static func cubicSymmetric(middleSpeed: Float) -> SKActionTimingFunction {
        let a = 4 * (1 - middleSpeed)
        let b = 6 * (middleSpeed - 1)
        let c = 3 - 2 * middleSpeed
        
        return { (time: Float) in
            return ((a * time + b) * time + c) * time
        }
    }
}

public extension SKAction {

    public enum Direction {
        case left
        case right
        case up
        case down
        
        public var isVertical: Bool {
            switch (self) {
                case .left: return false
                case .right: return false
                case .up: return true
                case .down: return true
            }
        }
        
        public var dx: CGFloat {
            switch (self) {
                case .left: return -1.0
                case .right: return 1.0
                case .up: return 0.0
                case .down: return 0.0
            }
        }
        
        public var dy: CGFloat {
            switch (self) {
                case .left: return 0.0
                case .right: return 0.0
                case .up: return 1.0
                case .down: return -1.0
            }
        }
        
    }
    
    public static func squishWithHeight(_ height: CGFloat, toFactor factor: CGFloat, direction: Direction, duration: TimeInterval) -> SKAction {
        let displacementAmount = (1.0 - factor) * height / 2.0
        let displacementX: CGFloat = direction.dx * displacementAmount
        let displacementY: CGFloat = direction.dy * displacementAmount
        
        let scaleDown = direction.isVertical
            ? SKAction.scaleX(by: 1.0, y: factor, duration: duration / 2.0)
            : SKAction.scaleX(by: factor, y: 1.0, duration: duration / 2.0)
        
        let scaleUp = direction.isVertical
            ? SKAction.scaleX(by: 1.0, y: 1.0/factor, duration: duration / 2.0)
            : SKAction.scaleX(by: 1.0/factor, y: 1.0, duration: duration / 2.0)
        
        let squish = SKAction.sequence([
            .group([
                scaleDown,
                .move(by: CGVector(dx: displacementX, dy:displacementY), duration: duration / 2.0)
                ]),
            .group([
                scaleUp,
                .move(by: CGVector(dx: -displacementX, dy:-displacementY), duration: duration / 2.0)
                ])
            ])
        
        return squish
    }
}
