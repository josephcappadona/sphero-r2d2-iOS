//
//  SmoothCameraNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-28.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class MovementAveragingNode: SKNode {
    var positions: [CGPoint]
    var positionIndex = 0
    
    public init(initialPosition: CGPoint, smoothness: Int) {
        positions = Array<CGPoint>(repeating: initialPosition, count: smoothness)
    
        super.init()
        
        position = initialPosition
    }
    
    public func targetUpdated(position targetPosition: CGPoint) {
        let subtractedPosition = positions[positionIndex]
        let scaleFactor = 1.0 / CGFloat(positions.count)
        position.x += (targetPosition.x - subtractedPosition.x) * scaleFactor
        position.y += (targetPosition.y - subtractedPosition.y) * scaleFactor
        positions[positionIndex] = targetPosition
        positionIndex = (positionIndex+1) % positions.count
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
