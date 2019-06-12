//
//  DeathStarCheckpointNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-20.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class DeathStarCheckpointNode: SKSpriteNode {
    
    public var isChecked: Bool {
        willSet {
            if newValue != isChecked {
                let imageName = newValue ? "tileCheckedCheckpoint" : "tileUncheckedCheckpoint"
                let texture = SKTexture(imageNamed: imageName)
                self.texture = texture
                
                if newValue {
                    self.flash()
                }
            }
        }
    }
    
    private let flashNode = SKSpriteNode(texture: DeathStarCheckpointNode.flashTexture)
    
    static let flashTexture: SKTexture? = {
        let square = SKShapeNode(rectOf: CGSize(width: 86.0, height: 86.0))
        square.glowWidth = 10.0
        
        square.fillColor = .white
        square.strokeColor = .white
        
        return SKView.renderingView.texture(from: square)
    }()

    public init(isChecked: Bool) {
        self.isChecked = isChecked
        
        let imageName = isChecked ? "tileCheckedCheckpoint" : "tileUncheckedCheckpoint"
        let texture = SKTexture(imageNamed: imageName)
    
        super.init(texture: texture, color: .clear, size: texture.size())
        
        let checkpointBody = SKPhysicsBody(circleOfRadius: 0.5 * DeathStarCell.size)
        checkpointBody.affectedByGravity = false
        checkpointBody.isDynamic = false
        checkpointBody.categoryBitMask = DeathStarEscapeScene.checkpointCategory
        physicsBody = checkpointBody
        zPosition = 1.0
        
        addChild(flashNode)
        flashNode.alpha = 0.0
        flashNode.blendMode = .screen
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func flash() {
        flashNode.alpha = 1.0
        flashNode.run(.fadeOut(withDuration: 0.25))
    }
}
