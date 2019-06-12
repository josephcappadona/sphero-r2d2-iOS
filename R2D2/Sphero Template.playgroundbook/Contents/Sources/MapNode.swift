//
//  MapNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-29.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class MapNode: SKNode {
    let radius: CGFloat = 150.0
    let scaleFactor: CGFloat
    let viewport: Circle
    
    private var trackedNodes: [(sceneNode:SKNode, mapNode: SKNode)] = []
    private let scannedTrackedNode = SKNode()
    
    public init(maze: DeathStarMaze) {
        
        var pathPoints = [CGPoint]()
        for cell in maze.cells {
            if cell.wallType == .Empty || cell.wallType == .OutOfBounds {
                pathPoints.append(cell.position)
            }
        }
        
        let minCircle = Circle.smallest(containing: pathPoints)
        viewport = Circle(center: minCircle.center, radius: (minCircle.radius + DeathStarCell.size * 2.0) as CGFloat)
        
        scaleFactor = radius / viewport.radius
        
        super.init()
        
        let textureNode = SKNode()
        
        let backgroundNode = SKShapeNode(circleOfRadius: radius)
        backgroundNode.glowWidth = 5.0
        backgroundNode.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        backgroundNode.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        backgroundNode.zPosition = -1.0
        backgroundNode.alpha = 0.55
        textureNode.addChild(backgroundNode)
        
        let squareSize = (DeathStarCell.size * scaleFactor * 1.25) as CGFloat
        
        let pathLayerNode = SKNode()
        
        for cell in maze.cells {
            if cell.wallType != .Empty && cell.wallType != .OutOfBounds {
                continue
            }
            
            let node = SKShapeNode(rectOf: CGSize(width: squareSize, height: squareSize))
            node.position = toViewport(cell.position)
            node.strokeColor = .clear
            node.fillColor = cell.wallType == .Empty ? .white : #colorLiteral(red: 0.3230441473, green: 0.3230441473, blue: 0.3230441473, alpha: 1)
            node.zPosition = cell.wallType == .Empty ? 1.0 : 0.0
            
            pathLayerNode.addChild(node)
            
            let distance = hypot(cell.position.x - viewport.center.x, cell.position.y - viewport.center.y) as CGFloat
            
            if distance > (minCircle.radius - DeathStarCell.size * 1.0) as CGFloat {
                let offset = (0.55 * DeathStarCell.size) as CGFloat
                
                let corners = [
                    CGPoint(x: cell.position.x + offset, y: cell.position.y + offset),
                    CGPoint(x: cell.position.x - offset, y: cell.position.y + offset),
                    CGPoint(x: cell.position.x + offset, y: cell.position.y - offset),
                    CGPoint(x: cell.position.x - offset, y: cell.position.y - offset)
                ]
                
                let firstAngle = atan2(corners[0].y - viewport.center.y, corners[0].x - viewport.center.x) as CGFloat
                
                var minAngleCorner = corners[0]
                var minAngleDiff = 0.0
                
                var maxAngleCorner = corners[0]
                var maxAngleDiff = 0.0
                
                for corner in corners.suffix(from: 1) {
                    let angle = atan2(corner.y - viewport.center.y, corner.x - viewport.center.x) as CGFloat
                    
                    let angleDiff = Double(angle - firstAngle).canonizedAngle(fullTurn: 2.0 * Double.pi)
                    
                    if angleDiff < minAngleDiff {
                        minAngleDiff = angleDiff
                        minAngleCorner = corner
                    }
                    
                    if angleDiff > maxAngleDiff {
                        maxAngleDiff = angleDiff
                        maxAngleCorner = corner
                    }
                }
                
                let minDiffX = (minAngleCorner.x - viewport.center.x) as CGFloat
                let minDiffY = (minAngleCorner.y - viewport.center.y) as CGFloat
                let maxDiffX = (maxAngleCorner.x - viewport.center.x) as CGFloat
                let maxDiffY = (maxAngleCorner.y - viewport.center.y) as CGFloat
                
                let minDistance = hypot(minDiffX, minDiffY)
                let maxDistance = hypot(maxDiffX, maxDiffY)
                
                let outsideDistance = (minCircle.radius + 0.75 * DeathStarCell.size) as CGFloat
                
                let minOutX = viewport.center.x + (minDiffX * (outsideDistance / minDistance)) as CGFloat
                let minOutY = viewport.center.y + (minDiffY * (outsideDistance / minDistance)) as CGFloat
                
                let minOut = CGPoint(x: minOutX, y: minOutY)
                
                let maxOutX = viewport.center.x + (maxDiffX * (outsideDistance / maxDistance)) as CGFloat
                let maxOutY = viewport.center.y + (maxDiffY * (outsideDistance / maxDistance)) as CGFloat
                
                let maxOut = CGPoint(x: maxOutX, y: maxOutY)
                
                let path = UIBezierPath()
                path.move(to: toViewport(minAngleCorner))
                path.addLine(to: toViewport(maxAngleCorner))
                path.addLine(to: toViewport(maxOut))
                path.addLine(to: toViewport(minOut))
                path.close()
                
                let shape = SKShapeNode(path: path.cgPath)
                shape.fillColor = node.fillColor
                shape.strokeColor = node.fillColor
                shape.zPosition = node.zPosition
                
                pathLayerNode.addChild(shape)
            }
        }
        
        let pathTexture = SKView.renderingView.texture(from: pathLayerNode, crop: CGRect(x: -radius, y: -radius, width: 2.0 * radius, height: 2.0 * radius))
        let pathNode = SKSpriteNode(texture: pathTexture)
        pathNode.alpha = 0.2
        textureNode.addChild(pathNode)
        
        for doorConfig in maze.doorConfigurations {
            if !doorConfig.isPassable { continue }
            
            let node = SKShapeNode(rectOf: CGSize(width: (0.75 * DeathStarCell.size * self.scaleFactor) as CGFloat, height: (DeathStarCell.size * self.scaleFactor * 0.125) as CGFloat))
            
            node.fillColor = #colorLiteral(red: 0.8453739289, green: 0.8453739289, blue: 0.8453739289, alpha: 1)
            node.strokeColor = node.fillColor
            
            node.zRotation = doorConfig.isHorizontal ? 0.0 : 0.5 * CGFloat.pi
            node.position = toViewport(doorConfig.position)
            
            textureNode.addChild(node)
        }
        
        for checkpoint in maze.checkpoints {
            let node = SKShapeNode(circleOfRadius: (DeathStarCell.size * self.scaleFactor * 0.25) as CGFloat)
            node.fillColor = #colorLiteral(red: 0.5368303571, green: 0.9283516404, blue: 1, alpha: 1)
            node.strokeColor = #colorLiteral(red: 0.5368303571, green: 0.9283516404, blue: 1, alpha: 1)
            
            node.glowWidth = (DeathStarCell.size * self.scaleFactor * 0.25) as CGFloat
            node.position = toViewport(checkpoint)
            
            textureNode.addChild(node)
        }
        
        let texture = SKView.renderingView.texture(from: textureNode)
        
        let spriteNode = SKSpriteNode(texture: texture)
        addChild(spriteNode)
        addChild(scannedTrackedNode)
        scannedTrackedNode.alpha = 0.0
    }
    
    private var texturesByColor = [UIColor: SKTexture]()
    
    public func addTrackedNode(_ sceneNode: SKNode, color: UIColor, isScanned: Bool) {
        let texture: SKTexture?
        
        if let existingTexture = texturesByColor[color] {
            texture = existingTexture
        } else {
            let shapeNode = SKShapeNode(circleOfRadius: (DeathStarCell.size * scaleFactor * 0.25) as CGFloat)
            shapeNode.fillColor = color
            shapeNode.strokeColor = color
            shapeNode.glowWidth = DeathStarCell.size * scaleFactor * 0.5
            texture = SKView.renderingView.texture(from: shapeNode)
            
            texturesByColor[color] = texture
        }
        
        addTrackedNode(sceneNode, texture: texture, isScanned: isScanned)
    }
    
    public func addTrackedNode(_ sceneNode: SKNode, texture: SKTexture?, isScanned: Bool) {
        let mapNode = SKSpriteNode(texture: texture)
        mapNode.blendMode = .add
        mapNode.position = toViewport(sceneNode.position)
        
        if isScanned {
            scannedTrackedNode.addChild(mapNode)
        } else {
            addChild(mapNode)
        }
        
        trackedNodes.append((
            sceneNode: sceneNode,
            mapNode: mapNode
        ))
    }
    
    public func update(_ currentTime: TimeInterval) {
        for (sceneNode, mapNode) in trackedNodes {
            mapNode.position = toViewport(sceneNode.position)
        }
    }
    
    public func setScanning(_ isScanning: Bool) {
        scannedTrackedNode.removeAllActions()
        
        scannedTrackedNode.run(.fadeAlpha(to: isScanning ? 1.0 : 0.0, duration: 0.5))
    }
    
    private func toViewport(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: (point.x - viewport.center.x) * scaleFactor,
            y: (point.y - viewport.center.y) * scaleFactor
        )
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
