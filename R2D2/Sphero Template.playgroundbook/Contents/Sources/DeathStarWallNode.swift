//
//  DeathStarWallNode.swift
//  DeathStarEscape
//
//  Created by Anthony Blackman on 2017-06-21.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class DeathStarWallNode: SKSpriteNode {

    static let backgroundColor = #colorLiteral(red: 0.3178062439, green: 0.3171053529, blue: 0.338008374, alpha: 1)

    static let doorEmptyTexture: SKTexture? = {
        return SKTexture(imageNamed: "tileStrips")
    }()
    
    static let emptyTexture: SKTexture? = {
        return SKTexture(imageNamed: "tileHash")
    }()
    
    static let straightTexture: SKTexture? = {
        let background = SKSpriteNode(imageNamed: "tilePlain")
        
        let wall = SKSpriteNode(imageNamed: "wallStrip")
        wall.zRotation = 0.5 * CGFloat.pi
        background.addChild(wall)
        
        return SKView.renderingView.texture(from: background)
    }()
    
    static let doorStraightTexture: SKTexture? = {
        let background = SKSpriteNode(imageNamed: "tileStrips")
        background.zRotation = 0.5 * CGFloat.pi
        
        let wall = SKSpriteNode(imageNamed: "wallStrip")
        background.addChild(wall)
        
        return SKView.renderingView.texture(from: background)
    }()
    
    static let cornerTexture: SKTexture? = {
        let background = SKSpriteNode(imageNamed: "tilePlain")
        
        let wall = SKSpriteNode(imageNamed: "wallCorner")
        wall.zRotation = CGFloat.pi
        background.addChild(wall)
        
        return SKView.renderingView.texture(from: background)
    }()
    
    static let alcoveTexture: SKTexture? = {
        let background = SKSpriteNode(imageNamed: "tilePlain")
        
        let wall = SKSpriteNode(imageNamed: "wallAlcove")
        wall.zRotation = -0.5 * CGFloat.pi
        background.addChild(wall)
        
        return SKView.renderingView.texture(from: background)
    }()

    public init(cell: DeathStarCell) {
        let texture: SKTexture?
        let body: SKPhysicsBody?
        let rotation = cell.rotation
    
        switch cell.wallType {
            case .Empty, .OutOfBounds:
                texture = cell.isNearDoor ? DeathStarWallNode.doorEmptyTexture : DeathStarWallNode.emptyTexture
                body = nil
            
            case .Filled:
                texture = nil
                body = nil
            
            case .Straight:
                texture = cell.isNearDoor ? DeathStarWallNode.doorStraightTexture : DeathStarWallNode.straightTexture
                body = SKPhysicsBody(
                    rectangleOf: CGSize(width: DeathStarCell.size, height: 0.5 * DeathStarCell.size),
                    center: CGPoint(x: 0.0, y: -0.25 * DeathStarCell.size)
                )
            
            case .Corner:
                texture = DeathStarWallNode.cornerTexture
                body = SKPhysicsBody(
                    rectangleOf: CGSize(width: 0.5 * DeathStarCell.size, height: 0.5 * DeathStarCell.size),
                    center: CGPoint(x: 0.25 * DeathStarCell.size, y: -0.25 * DeathStarCell.size)
                )
            
            case .Alcove:
                texture = DeathStarWallNode.alcoveTexture
                body = SKPhysicsBody(bodies: [
                    SKPhysicsBody(
                        rectangleOf: CGSize(width: DeathStarCell.size, height: 0.5 * DeathStarCell.size),
                        center: CGPoint(x: 0.0, y: 0.25 * DeathStarCell.size)
                    ),
                    SKPhysicsBody(
                        rectangleOf: CGSize(width: 0.5 * DeathStarCell.size, height: 0.5 * DeathStarCell.size),
                        center: CGPoint(x: -0.25 * DeathStarCell.size, y: -0.25 * DeathStarCell.size)
                    )
                ])
        }
        
        body?.isDynamic = false
        body?.categoryBitMask = DeathStarEscapeScene.wallCategory
        
        super.init(texture: texture, color: .clear, size: texture?.size() ?? .zero)
        
        position = cell.position
        zRotation = rotation
        
        physicsBody = body
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
