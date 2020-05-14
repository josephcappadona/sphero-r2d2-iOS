//
//  DeathStarLockNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-08-18.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class DeathStarLockNode: SKNode {
    let lockBaseNode = SKSpriteNode(imageNamed: "lockBase")
    let lockBottomNode = SKSpriteNode(imageNamed: "lockBottomLayer")
    let lockTopNode = SKSpriteNode(imageNamed: "lockTopLayer")
    
    let gearNormalTexture = SKTexture(imageNamed: "lockGear")
    let gearHackedTexture = SKTexture(imageNamed: "lockGearUnlocked")
    
    let textBackgroundNormalTexture = SKTexture(imageNamed: "backgroundBehindText")
    let textBackgroundHackedTexture = SKTexture(imageNamed: "backgroundBehindTextHacked")
    
    let gearNode: SKSpriteNode
    let textBackgroundNode: SKSpriteNode
    
    let codeContainerNode = SKSpriteNode(imageNamed: "backgroundBehindText")
    var codeNodes = [SKLabelNode]()

    public override init() {
        gearNode = SKSpriteNode(texture: gearNormalTexture)
        textBackgroundNode = SKSpriteNode(texture: textBackgroundNormalTexture)
        
        super.init()
        
        alpha = 0.0
        
        zPosition = 50.0
        
        lockBaseNode.zPosition = 1.0
        lockBottomNode.zPosition = 2.0
        lockTopNode.zPosition = 3.0
        gearNode.zPosition = 4.0
        textBackgroundNode.zPosition = 5.0
        codeContainerNode.zPosition = 6.0
        
        [lockBaseNode,lockBottomNode,lockTopNode,gearNode,textBackgroundNode].forEach(self.addChild)
        
        textBackgroundNode.alpha = 1.0
        
        for i in 0 ..< 4 {
            let codeNode = SKLabelNode()
            codeNode.fontSize = 36.0
            codeNode.fontName = UIFont.arcadeFontName
            codeNode.position.x = (CGFloat(i) - 1.5) * 20.0
            codeNode.position.y = -10
            codeNodes.append(codeNode)
        }
        
        addChild(codeContainerNode)
        for codeNode in codeNodes {
            codeContainerNode.addChild(codeNode)
        }
        codeContainerNode.alpha = 0.0
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        alpha = 1.0
        
        self.gearNode.texture = gearNormalTexture
        
        for (index,node) in [gearNode, lockTopNode, lockBottomNode, lockBaseNode].enumerated() {
            popIn(node: node, after: Double(index) * 0.1)
        }
    }
    
    public func hide() {
        for (index,node) in [gearNode, lockTopNode, lockBottomNode, lockBaseNode].enumerated() {
            popOut(node: node, after: Double(index) * 0.1)
        }
    }
    
    public func show(code: Int, isCorrect: Bool) {
        let color: UIColor = isCorrect ? #colorLiteral(red: 0.5988022685, green: 0.8814128041, blue: 0.2850577533, alpha: 1) : #colorLiteral(red: 0.8665904403, green: 0.8667154908, blue: 0.8665630817, alpha: 1)
    
        let codeString = String(format: "%.4d", code)
        for (node, char) in zip(codeNodes, codeString.characters) {
            node.text = String(char)
            node.fontColor = color
        }
        
        codeContainerNode.removeAllActions()
        codeContainerNode.alpha = 1.0
        
        codeContainerNode.run(
            .sequence([
                .wait(forDuration: 0.25),
                .fadeOut(withDuration: 0.5)
            ])
        )
        
        self.gearNode.texture = isCorrect ? gearHackedTexture : gearNormalTexture
        
        let gearNodeRotation = (CGFloat(arc4random_uniform(2)) * 2.0 - 1.0) * 0.1 * CGFloat.pi
        self.gearNode.removeAllActions()
        self.gearNode.run(.rotate(byAngle: gearNodeRotation, duration: 0.08))
        
        let topNodeRotation = (CGFloat(arc4random_uniform(2)) * 2.0 - 1.0) * 0.075 * CGFloat.pi
        self.lockTopNode.removeAllActions()
        self.lockTopNode.run(.rotate(byAngle: topNodeRotation, duration: 0.08))
        
        let bottomNodeRotation = (CGFloat(arc4random_uniform(2)) * 2.0 - 1.0) * 0.05 * CGFloat.pi
        self.lockBottomNode.removeAllActions()
        self.lockBottomNode.run(.rotate(byAngle: bottomNodeRotation, duration: 0.08))
    }
    
    private func popIn(node: SKNode, after delay: TimeInterval) {
        node.removeAllActions()
        
        node.setScale(0.0)
        node.zRotation = CGFloat.pi
        
        let expand = SKAction.scale(to: 1.05, duration: 0.5)
        expand.timingFunction = TimingFunctions.cubicEaseInOut
        
        let contract = SKAction.scale(to: 1.0, duration: 0.3)
        contract.timingFunction = TimingFunctions.cubicEaseInOut
        
        let spin = SKAction.rotate(toAngle: 0.0, duration: 0.8, shortestUnitArc: false)
        spin.timingFunction = TimingFunctions.cubicEaseInOut
        
        node.run(.sequence([
            .wait(forDuration: delay),
            .group([
                spin,
                .sequence([
                    expand,
                    contract
                ])
            ])
        ]))
    }
    
    private func popOut(node: SKNode, after delay: TimeInterval) {
        node.removeAllActions()
        
        node.setScale(1.0)
        
        let expand = SKAction.scale(to: 1.1, duration: 0.3)
        expand.timingFunction = TimingFunctions.cubicEaseInOut
        
        let contract = SKAction.scale(to: 0.0, duration: 0.5)
        contract.timingFunction = TimingFunctions.cubicEaseInOut
        
        let spin = SKAction.rotate(byAngle: -CGFloat.pi, duration: 0.8)
        spin.timingFunction = TimingFunctions.cubicEaseInOut
        
        node.run(.sequence([
            .wait(forDuration: delay),
            .group([
                spin,
                .sequence([
                    expand,
                    contract
                ])
            ])
        ]))
    }
}
