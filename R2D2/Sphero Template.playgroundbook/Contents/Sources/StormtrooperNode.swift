//
//  StormtrooperNode.swift
//  DeathStarEscape
//
//  Created by Anthony Blackman on 2017-06-22.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import SpriteKit
import UIKit


private let confusedActionKey = "😕"

public class StormtrooperNode: SKSpriteNode {
    public let path: [CGPoint]
    private var pathIndex = 0
    public var nextPatrolPoint: CGPoint {
        get {
            return path[pathIndex]
        }
    }
    public var chasingPoint: CGPoint? {
        didSet {
            if chasingPoint != nil && isConfused {
                isConfused = false
                removeAction(forKey: confusedActionKey)
            }
        }
    }
    public var isConfused = false
    
    public let patrolSpeed = 200.0 as CGFloat
    public let chasingSpeed = 300.0 as CGFloat
    
    public var lastLaserTimestamp: TimeInterval = 0.0
    private var shotLaserCount = 0
    private let playLaserSound = SKAction.playSoundFileNamed("gun", waitForCompletion: false)
    
    public private(set) var isPatrolling = true
    
    let rightFootNode = SKSpriteNode(imageNamed: "stormtrooper-foot-right")
    let leftFootNode = SKSpriteNode(imageNamed: "stormtrooper-foot-right")
    let headNode = SKSpriteNode(imageNamed: "stormtrooper-head")

    public static let stormtrooperActiveTexture: SKTexture? = {
        let node = SKSpriteNode(imageNamed: "stormtrooperTop")
        
        node.zRotation = 0.5 * CGFloat.pi
        
        return SKView.renderingView.texture(from: node)
    }()

    public static let stormtrooperInactiveTexture: SKTexture? = {
        let node = SKSpriteNode(imageNamed: "stormtrooperArmsInactive")
        
        node.zRotation = 0.5 * CGFloat.pi
        
        return SKView.renderingView.texture(from: node)
    }()
    
    public let inactiveArmsNode = SKSpriteNode(texture: StormtrooperNode.stormtrooperInactiveTexture)

    public init(path: [CGPoint]) {
        self.path = path
    
        let texture = StormtrooperNode.stormtrooperActiveTexture
        super.init(texture: texture, color: .clear, size: texture?.size() ?? .zero)
        
        anchorPoint.x = 0.25
        
        position = path.first ?? .zero
        
        let body = SKPhysicsBody(circleOfRadius: 62.0, center: CGPoint(x: 10.0, y: 0.0))
        
        body.affectedByGravity = false
        body.categoryBitMask = DeathStarEscapeScene.stormtrooperCategory
        body.collisionBitMask = DeathStarEscapeScene.wallCategory
        
        physicsBody = body
        
        zPosition = 20.0
        rightFootNode.zPosition = -0.1
        leftFootNode.zPosition = -0.1
        
        rightFootNode.zRotation = 0.5 * CGFloat.pi
        leftFootNode.zRotation = 0.5 * CGFloat.pi
        
        rightFootNode.position.x = 0.0
        leftFootNode.position.x = 0.0
        
        rightFootNode.position.y = -20.0
        leftFootNode.position.y = 20.0
        
        headNode.zRotation = 0.5 * CGFloat.pi
        headNode.position.x = -25.0
        
        addChild(inactiveArmsNode)
        addChild(rightFootNode)
        addChild(leftFootNode)
        addChild(headNode)
        
        walkFeet()
        startLooking()
        
        self.texture = nil
        inactiveArmsNode.position.x = 15.0
        inactiveArmsNode.position.y = -2.5
    }
    
    private func startLooking() {
        headNode.removeAllActions()
        
        let lookLeft = SKAction.rotate(toAngle: 0.7 * CGFloat.pi, duration: 1.5)
        let lookRight = SKAction.rotate(toAngle: 0.3 * CGFloat.pi, duration: 1.5)
        
        lookLeft.timingFunction = TimingFunctions.cubicEaseInOut
        lookRight.timingFunction = TimingFunctions.cubicEaseInOut
        
        headNode.run(.repeatForever(.sequence([lookRight, lookLeft])))
    }
    
    private func stopLooking() {
        headNode.removeAllActions()
    
        let lookCenter = SKAction.rotate(toAngle: 0.5 * CGFloat.pi, duration: 0.7)
        
        lookCenter.timingFunction = TimingFunctions.cubicEaseInOut
        
        headNode.run(lookCenter)
    }
    
    private func walkFeet() {
        leftFootNode.removeAllActions()
        rightFootNode.removeAllActions()
        
        let unrotate = SKAction.rotate(toAngle: 0.5 * CGFloat.pi, duration: 0.25)
        unrotate.timingFunction = TimingFunctions.cubicEaseInOut
        
        leftFootNode.run(unrotate)
        rightFootNode.run(unrotate)
    
        let moveForwardAction = SKAction.moveTo(x: 25.0, duration: 0.5)
        moveForwardAction.timingFunction = { (t: Float) in
            // Start and end with slope -z
            // So that this smoothly transitions between forwards and backwards foot movement.
            let z = 1.0 as Float
            
            let t2 = t*t
            let t3 = t2*t
            
            return -2.0*(z+1.0)*t3 + 3*(z+1.0)*t2 - z*t
        }
        
        let moveBackwardAction = SKAction.moveTo(x: -25.0, duration: 0.5)
        
        let footAction = SKAction.repeatForever(.sequence([
            moveForwardAction, moveBackwardAction
        ]))
        
        rightFootNode.run(footAction)
        leftFootNode.run(.sequence([
            .wait(forDuration: (moveForwardAction.duration + moveBackwardAction.duration) / 2.0),
            footAction
        ]))
    }
    
    private func rotateFeet() {
        leftFootNode.removeAllActions()
        rightFootNode.removeAllActions()
        
        let center = SKAction.moveTo(x: 5.0, duration: 0.25)
        center.timingFunction = TimingFunctions.cubicEaseInOut
        
        leftFootNode.run(center)
        rightFootNode.run(center)
        
        leftFootNode.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.8*CGFloat.pi, duration: 0.4),
            .rotate(toAngle: 0.4*CGFloat.pi, duration: 0.4)
        ])))
        rightFootNode.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.2*CGFloat.pi, duration: 0.4),
            .rotate(toAngle: 0.6*CGFloat.pi, duration: 0.4)
        ])))
    }
    
    private func stopFeet() {
        leftFootNode.removeAllActions()
        rightFootNode.removeAllActions()
    }
    
    public func update() {
        guard
            let deathStarScene = scene as? DeathStarEscapeScene,
            let body = physicsBody
            else { return }
        
        if deathStarScene.artooNode.wasCaptured {
            body.velocity = .zero
            body.angularVelocity = 0.0
            stopFeet()
            return
        }
        
        let currentTime = deathStarScene.currentTime
        
        let isArtooVisible = self.checkVisibility(artooNode: deathStarScene.artooNode, maze: deathStarScene.maze, currentTime: currentTime)
        
        if isConfused {
            return
        }
    
        let destination = chasingPoint ?? nextPatrolPoint
        let speed = UIAccessibilityIsVoiceOverRunning() ? 100.0 : chasingPoint == nil ? patrolSpeed : chasingSpeed
        
        let deltaX = destination.x - position.x
        let deltaY = destination.y - position.y
        
        let distance = hypot(deltaX, deltaY)
        
        // Stop chasing when you're within 50 of artoo's last seen position,
        // since artoo can get closer to walls than stormtroopers, so the exact position of artoo
        // might not be reachable.
        
        if distance < 5.0 || chasingPoint != nil && distance < 50.0 {
            // reached(ish) the destination.
            // Go to next patrol point.
            
            if chasingPoint != nil {
                chasingPoint = nil
                isConfused = true
                body.velocity = .zero
                body.angularVelocity = 0.0
                shotLaserCount = 0
                rotateFeet()
                self.texture = nil
                self.inactiveArmsNode.alpha = 1.0
                
                run(
                    .sequence([
                        .rotate(byAngle: 2 * CGFloat.pi, duration: 2.0),
                        .run { [weak self] in
                            self?.stopFeet()
                        },
                        .wait(forDuration: 1.0)
                    ])
                ) { [weak self] in
                    self?.isConfused = false
                    self?.walkFeet()
                    self?.startLooking()
                }
            }
            
            pathIndex = (pathIndex + 1) % path.count
            
            return
        }
        
        guard let direction = deathStarScene.maze.directionForPath(fromPoint: position, toPoint: destination) else { return }
        
        let angle = atan2(direction.dy, direction.dx)
        
        rotate(towards: angle, maxSpeed: CGFloat.pi)
        
        if UIAccessibilityIsVoiceOverRunning() && isArtooVisible {
            // In accessibility mode, stormtroopers stop while shooting at artoo.
            
            body.velocity = .zero
        } else {
            body.velocity.dx = direction.dx * speed
            body.velocity.dy = direction.dy * speed
        }
    }
    
    private func checkVisibility(artooNode: ArtooDetooNode, maze: DeathStarMaze, currentTime: TimeInterval) -> Bool {
        
        let diffX = artooNode.position.x - position.x
        let diffY = artooNode.position.y - position.y
        
        let distance = hypot(diffX, diffY)
        
        if distance > 500.0 { return false }
        
        // Ignore angle, visibility when artoo is very close (the stormtrooper has ears too, right?)
        if distance > 150.0 {
            let angle = atan2(diffY, diffX)
            
            let headRotation = zRotation + headNode.zRotation - 0.5 * CGFloat.pi
            
            let angleDiff = abs((angle - headRotation).truncatingRemainder(dividingBy: 2.0*CGFloat.pi))
            
            let angleDistance = min(angleDiff, 2.0 * CGFloat.pi - angleDiff)
            
            if angleDistance >  0.3 * CGFloat.pi {
                return false
            }
            
            if !maze.isVisible(point: artooNode.position, fromPoint: position) {
                return false
            }
        }
        
        // artoo is visible.
        if currentTime - lastLaserTimestamp > 0.75 {
            lastLaserTimestamp = currentTime
            shoot(at: artooNode.position)
        }
        
        if chasingPoint == nil,
            let scene = scene as? DeathStarEscapeScene,
            UIAccessibilityIsVoiceOverRunning() {
            // Was patrolling, now sees artoo.
            // Tell VoiceOver users where the stormtrooper is.
            
            
            // Use negative diffs to get position of stormtrooper relative to artoo, rather than vice-versa.
            let diff = CGVector(dx: -diffX, dy: -diffY)
            
            scene.speaker.speak(
                String(
                    format: NSLocalizedString("deathStar.accessibility.detectedByStormtrooper", value: "Stormtrooper %@ can see R2D2", comment: "'%@ is replaced with direction. ie Stormtrooper left can see R2D2. Sentence is brief as it is being read by voice over during gameplay"),
                    scene.description(forDirection: diff)
                )
            )
        }
        
        if chasingPoint == nil {
            // Was patrolling, now sees artoo.
            stopLooking()
        }
        
        chasingPoint = artooNode.position
        
        return true
    }
    
    private func shoot(at target: CGPoint) {
//        let xDiff = target.x - position.x
//        let yDiff = target.y - position.y
//
//        let angle = atan2(yDiff, xDiff)
//        var angleDiff = (angle - zRotation).truncatingRemainder(dividingBy: 2.0 * CGFloat.pi)
//        if angleDiff > CGFloat.pi {
//            angleDiff -= 2.0 * CGFloat.pi
//        } else if angleDiff < -CGFloat.pi {
//            angleDiff += 2.0 * CGFloat.pi
//        }
//
//        // Don't shoot at targets behind you.
//        if abs(angleDiff) > CGFloat.pi / 4.0 {
//            return
//        }
//
//        run(playLaserSound)
//
//        shotLaserCount += 1
//
//        let laserDistance = 160.0 as CGFloat
//        let laserDiffX = laserDistance * cos(zRotation)
//        let laserDiffY = laserDistance * sin(zRotation)
//        let laserPosition = CGPoint(x: position.x + laserDiffX, y: position.y + laserDiffY)
//        let laserTargetPosition = CGPoint(x: position.x + 2.0*laserDiffX, y: position.y + 2.0*laserDiffY)
//
//        self.scene?.addChild(LaserNode(position: laserPosition, target: laserTargetPosition, canHitArtoo: false))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
