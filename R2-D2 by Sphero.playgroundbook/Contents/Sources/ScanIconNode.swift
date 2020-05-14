//
//  ScanIconNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-27.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class ScanIconNode: SKNode {
    static let arrowTexture: SKTexture? = {
        let path = UIBezierPath()
        
        let halfHeight = 30.0
        let width = 50.0
        
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: -width, y: halfHeight))
        path.addQuadCurve(to: CGPoint(x: -width, y: -halfHeight), controlPoint: CGPoint(x: -0.8*width, y: 0.0))
        path.addLine(to: .zero)
        
        let node = SKShapeNode(path: path.cgPath)
        node.fillColor = #colorLiteral(red: 0.9560486219, green: 0.2798108579, blue: 0.2977563055, alpha: 1)
        node.strokeColor = node.fillColor
        
        return SKView.renderingView.texture(from: node)
    }()
    
    static let circleTexture: SKTexture? = {
        let node = SKShapeNode(circleOfRadius: 50.0)
        node.strokeColor = #colorLiteral(red: 0.9560486219, green: 0.2798108579, blue: 0.2977563055, alpha: 1)
        node.fillColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        node.lineWidth = 10.0
        
        return SKView.renderingView.texture(from: node)
    }()

    let arrowRotationNode = SKNode()
    let arrowNode = SKSpriteNode(texture: ScanIconNode.arrowTexture)
    let circleNode = SKSpriteNode(texture: ScanIconNode.circleTexture)
    let iconNode: SKNode
    public let scannedNode: SKNode
    public let sourceNode: SKNode
    let maxDistance = 2000.0 as CGFloat
    let createdTime: TimeInterval
    
    public init(icon: SKTexture?, scannedNode: SKNode, sourceNode: SKNode) {
        self.iconNode = SKSpriteNode(texture: icon)
        self.iconNode.setScale(0.7)
        self.scannedNode = scannedNode
        self.sourceNode = sourceNode
        self.createdTime = (scannedNode.scene as? DeathStarEscapeScene)?.currentTime ?? 0.0
        
        super.init()
        
        addChild(circleNode)
        addChild(arrowRotationNode)
        arrowRotationNode.addChild(arrowNode)
        arrowNode.anchorPoint.x = 1.0
        arrowNode.position.x = 115.0
        circleNode.addChild(iconNode)
        zPosition = 20.0
    }
    
    public func update(xMaxOffset: CGFloat, yMaxOffset: CGFloat) {
        let currentTime: TimeInterval = (scene as? DeathStarEscapeScene)?.currentTime ?? 0.0
        
        let xPositionDiff = scannedNode.position.x - sourceNode.position.x
        let yPositionDiff = scannedNode.position.y - sourceNode.position.y
        
        let distance = hypot(xPositionDiff, yPositionDiff)
        let angle = atan2(yPositionDiff, xPositionDiff)
        
        if distance > maxDistance {
            alpha = 0.0
            return
        }
     
        let xOffsetRatio = abs(xPositionDiff) / xMaxOffset
        let yOffsetRatio = abs(yPositionDiff) / yMaxOffset
        let offsetRatio = max(xOffsetRatio, yOffsetRatio)
        
        if offsetRatio < 0.8 {
            // Node is on screen.
            alpha = 0.0
            return
        }
        
        if offsetRatio < 1.0 {
            alpha = (offsetRatio - 0.8) * 5.0 * 0.75
        } else if distance > maxDistance - 200.0 {
            alpha = (maxDistance - distance) / 200.0 * 0.75
        } else {
            alpha = 0.75
        }
        
        if currentTime - createdTime < 0.5 {
            alpha *= 2.0 * CGFloat(currentTime - createdTime)
        }
        
        let xDiffHat = xPositionDiff / distance
        let yDiffHat = yPositionDiff / distance
        
        let xMaxCircleDistance = xMaxOffset / abs(xDiffHat)
        let yMaxCircleDistance = yMaxOffset / abs(yDiffHat)
        
        let maxCircleDistance = min(xMaxCircleDistance, yMaxCircleDistance)
        
        let circleDistance = min(distance, maxCircleDistance) - 125.0
        
        arrowRotationNode.zRotation = angle
        position.x = xDiffHat * circleDistance
        position.y = yDiffHat * circleDistance
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
