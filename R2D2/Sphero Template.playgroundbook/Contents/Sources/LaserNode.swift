//
//  LaserNode.swift
//  DeathStarEscape
//
//  Created by Anthony Blackman on 2017-06-23.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit


let imperialLaserTexture: SKTexture? = {
    let shape = SKShapeNode(rectOf: LaserNode.laserSize, cornerRadius: 5.0)
    
    shape.fillColor = #colorLiteral(red: 0.9105071188, green: 0, blue: 0, alpha: 1)
    shape.strokeColor = shape.fillColor
    
    shape.glowWidth = 5.0
    
    return SKView.renderingView.texture(from: shape)
}()

public class LaserNode: SKSpriteNode {
    public static let laserSize = CGSize(width: 150.0, height: 2.0)
    public static let laserSpeed = 5000.0 as CGFloat

    public init(position: CGPoint, target: CGPoint, canHitArtoo: Bool) {
        super.init(texture: imperialLaserTexture, color: .clear, size: imperialLaserTexture?.size() ?? .zero)
    
        let speed: CGFloat = LaserNode.laserSpeed
        
        blendMode = .add
        
        let angle = atan2(target.y - position.y, target.x - position.x)
        
        self.position = position
        zRotation = angle
        // On top of artoo, below stormtroopers
        zPosition = 15.0
        
        let body = SKPhysicsBody(rectangleOf: LaserNode.laserSize)
        body.velocity.dx = speed * cos(angle)
        body.velocity.dy = speed * sin(angle)
        body.categoryBitMask = DeathStarEscapeScene.laserCategory
        body.contactTestBitMask = DeathStarEscapeScene.wallCategory
        if canHitArtoo {
            body.contactTestBitMask |= DeathStarEscapeScene.artooCategory
        }
        body.collisionBitMask = 0
        
        // From Apple's docs:
        // "This property should be set to true on small, fast moving bodies."
        body.usesPreciseCollisionDetection = true
        
        physicsBody = body
    }
    
    public func beganContact(withNode otherNode: SKNode) {
        guard
            let body = physicsBody,
            let scene = (scene as? DeathStarEscapeScene),
            let explosion = SKEmitterNode(fileNamed: "LaserExplosion")
            else { return }
    
        removeFromParent()
        
        let otherCategory = otherNode.physicsBody?.categoryBitMask ?? 0
        
        if otherCategory & DeathStarEscapeScene.artooCategory != 0 {
            // R2-D2 was hit by a laser.
            
            (otherNode as? ArtooDetooNode)?.getZapped()
            scene.artooWasCaptured(waitDuration: 8.0)
        }
        
        let laserFront = LaserNode.laserSize.width / 2.0 / LaserNode.laserSpeed
        explosion.position.x = position.x + body.velocity.dx * laserFront
        explosion.position.y = position.y + body.velocity.dy * laserFront
        explosion.zRotation = zRotation + CGFloat.pi
        
        scene.addChild(explosion)
        
        explosion.run(.fadeOut(withDuration: 0.15)) {
            explosion.removeFromParent()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
