//
//  DeathStarDoorNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-27.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class DeathStarDoorNode: SKSpriteNode {

    static let frameTexture: SKTexture? = {
        let node = SKSpriteNode(imageNamed: "blastDoorBrackets")
        node.zRotation = 0.5 * CGFloat.pi
        
        return SKView.renderingView.texture(from: node)
    }()
    
    static let doorTexture: SKTexture? = {
        return SKTexture(imageNamed: "blastDoor")
    }()
    
    static let cropTexture: SKTexture? = {
        let node = SKShapeNode(rectOf: CGSize(width: 20.0, height: 2.0 * DeathStarCell.size - 2.0))
        
        node.fillColor = .white
        
        return SKView.renderingView.texture(from: node)
    }()
    
    static let doorHackingTexture: SKTexture? = {
        return SKTexture(imageNamed: "blastDoorHacking")
    }()
    
    static let doorHackedTexture: SKTexture? = {
        return SKTexture(imageNamed: "blastDoorHacked")
    }()
    
    static let hackingGlowTexture: SKTexture? = {
        let node = SKShapeNode(rectOf: CGSize(width: 20.0, height: 2.0 * DeathStarCell.size))
        node.glowWidth = 10.0
        node.fillColor = #colorLiteral(red: 0.7764018178, green: 0.7765145898, blue: 0.7763771415, alpha: 1)
        node.strokeColor = node.fillColor
        node.alpha = 0.5
        
        return SKView.renderingView.texture(from: node, crop: CGRect(x: -20, y: -DeathStarCell.size, width: 40.0, height: 2.0 * DeathStarCell.size))
    }()
    
    static let hackedGlowTexture: SKTexture? = {
        let node = SKShapeNode(rectOf: CGSize(width: 20.0, height: 2.0 * DeathStarCell.size))
        node.glowWidth = 10.0
        node.fillColor = #colorLiteral(red: 0.3772626519, green: 0.6600916982, blue: 0.06266611069, alpha: 1)
        node.strokeColor = node.fillColor
        node.alpha = 0.5
        
        return SKView.renderingView.texture(from: node, crop: CGRect(x: -20, y: -DeathStarCell.size, width: 40.0, height: 2.0 * DeathStarCell.size))
    }()
    
    let topDoor: SKSpriteNode
    let bottomDoor: SKSpriteNode
    
    let topDoorEffect: SKSpriteNode
    let bottomDoorEffect: SKSpriteNode
    let glowNode: SKSpriteNode
    
    let solidNode: SKNode
    let solidBody: SKPhysicsBody
    
    var lastOpenTimestamp: TimeInterval = 0.0
    let openDuration: TimeInterval = 2.0
    public let isHorizontal: Bool
    public let code = Int(arc4random_uniform(9998)) + 1
    
    public let isPassable: Bool
    
    public var isHackedOpen = false {
        didSet {
            updateDoorPositions()
        }
    }
    
    private var nearbyStormtrooperCount = 0 {
        didSet {
            updateDoorPositions()
        }
    }
    
    public private(set) var isOpen = false
    
    public init(config: DoorConfiguration) {
        isPassable = config.isPassable
    
        topDoor = isPassable ? SKSpriteNode(texture: DeathStarDoorNode.doorTexture) : SKSpriteNode(imageNamed: "doorNoEntry")
        bottomDoor = isPassable ? SKSpriteNode(texture: DeathStarDoorNode.doorTexture) : SKSpriteNode()
        
        topDoorEffect = SKSpriteNode(texture: DeathStarDoorNode.doorHackingTexture)
        bottomDoorEffect = SKSpriteNode(texture: DeathStarDoorNode.doorHackingTexture)
        topDoorEffect.alpha = 0.0
        bottomDoorEffect.alpha = 0.0
        
        topDoor.addChild(topDoorEffect)
        bottomDoor.addChild(bottomDoorEffect)
        
        glowNode = SKSpriteNode(texture: DeathStarDoorNode.hackingGlowTexture)
        glowNode.alpha = 0.0
        
        solidBody = SKPhysicsBody(rectangleOf: CGSize(width: 20.0, height: 2.0 * DeathStarCell.size))
        solidBody.isDynamic = false
        solidBody.categoryBitMask = DeathStarEscapeScene.wallCategory
        
        let maskNode = SKSpriteNode(texture: DeathStarDoorNode.cropTexture)
        let cropNode = SKCropNode()
        cropNode.maskNode = maskNode
        
        solidNode = cropNode
        solidNode.physicsBody = solidBody
        
        if isPassable {
            topDoor.position.y = 20.0
            bottomDoor.position.y = -20.0
        }
        
        topDoor.zRotation = -0.5 * CGFloat.pi
        bottomDoor.zRotation = 0.5 * CGFloat.pi
        
        isHorizontal = config.isHorizontal
        
        super.init(texture: DeathStarDoorNode.frameTexture, color: .clear, size: DeathStarDoorNode.frameTexture?.size() ?? .zero)
        
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 150.0, height: 2.0 * DeathStarCell.size))
        body.isDynamic = false
        body.contactTestBitMask = DeathStarEscapeScene.stormtrooperCategory
        body.categoryBitMask = DeathStarEscapeScene.doorCategory
        body.collisionBitMask = 0
        physicsBody = body
        
        addChild(cropNode)
        
        cropNode.zPosition = -0.1
        cropNode.addChild(topDoor)
        cropNode.addChild(bottomDoor)
        
        zPosition = 1.0
        
        zRotation = isHorizontal ? 0.5 * CGFloat.pi : 0.0
        
        position = config.position
        
        glowNode.zPosition = -0.2
        addChild(glowNode)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show(code: Int) {
        for effect in [topDoorEffect, bottomDoorEffect] {
            effect.texture = code == self.code ? DeathStarDoorNode.doorHackedTexture : DeathStarDoorNode.doorHackingTexture
            
            effect.removeAllActions()
            effect.alpha = 1.0
            effect.run(.fadeOut(withDuration: 0.5))
        }
        
        glowNode.texture = code == self.code ? DeathStarDoorNode.hackedGlowTexture : DeathStarDoorNode.hackingGlowTexture
        
        glowNode.removeAllActions()
        glowNode.alpha = 1.0
        glowNode.run(.fadeOut(withDuration: 0.5))
        
        guard let scene = (self.scene as? DeathStarEscapeScene) else { return }
        
        scene.lockNode?.show(code: code, isCorrect: code == self.code)
    }
    
    public func contactBegan(withNode node: SKNode) {
        if let _ = node as? StormtrooperNode {
            nearbyStormtrooperCount += 1
            isHackedOpen = false
        }
    }
    
    public func contactEnded(withNode node: SKNode) {
        if let _ = node as? StormtrooperNode {
            nearbyStormtrooperCount -= 1
        }
    }
    
    private func updateDoorPositions() {
        let shouldBeOpen = nearbyStormtrooperCount != 0 || isHackedOpen
        
        if shouldBeOpen != isOpen {
            isOpen = shouldBeOpen
            
            let offset = isOpen ? 220.0 : 20.0
            
            topDoor.removeAllActions()
            bottomDoor.removeAllActions()
            
            topDoor.run(.move(to: CGPoint(x: 0, y: offset), duration: 0.5))
            bottomDoor.run(.move(to: CGPoint(x: 0, y: -offset), duration: 0.5))
            
            if let maze = (scene as? DeathStarEscapeScene)?.maze {
                maze.doorDidUpdateState(at: position, isHorizontal: isHorizontal, isOpen: isOpen)
            }
            
            if isOpen {
                solidNode.physicsBody = nil
            } else {
                solidNode.physicsBody = solidBody
            }
        }
    }
}
