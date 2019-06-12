//
//  ArtooDetooNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-27.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class ArtooDetooNode: SKSpriteNode {
    public let headNode: SKSpriteNode
    private let headTopNode: SKSpriteNode
    private let lifeScannerNode = SKSpriteNode(imageNamed: "life_scanner")
    private let headPanelNode = SKSpriteNode(imageNamed: "head_panel")
    private let armNode = SKSpriteNode(imageNamed: "computerArmTop")
    private let zapNode: SKSpriteNode
    
    public var currentTouch: UITouch? = nil
    private var currentTouchDirectionDescription = ""
    
    public private(set) var didReachEnd = false
    
    public var accessibilityDirection: CGVector? = nil {
        didSet {
            if accessibilityDirection == nil,
                let scene = (scene as? DeathStarEscapeScene) {
                
                scene.speakOpenDirections()
            }
        }
    }
    public var wasCaptured = false
    
    private static let scanActionKey = "scan"
    private static let hackActionKey = "hack"
    private var nearbyDoor: DeathStarDoorNode? = nil
    private var isScanning = false
    private var isHacking = false
    private var scanWaitStartTimestamp: TimeInterval? = nil
    public var isScanEnabled = false
    private let playIncorrectCodeSound = SKAction.playSoundFileNamed("ButtonPulse", waitForCompletion: false)
    private let playCorrectCodeSound = SKAction.playSoundFileNamed("door_open", waitForCompletion: false)
    
    public override var isPaused: Bool {
        get {
            return super.isPaused
        }
        
        set {
            super.isPaused = newValue
        }
    }
    
    static let bodyTexture: SKTexture? = {
        let node = SKSpriteNode(imageNamed: "body")
        node.zRotation = -0.5 * CGFloat.pi
        return SKView.renderingView.texture(from: node)
    }()
    
    static let headTexture: SKTexture? = {
        let node = SKSpriteNode(imageNamed: "head_outline")
        node.zRotation = -0.5 * CGFloat.pi
        return SKView.renderingView.texture(from: node)
    }()

    static let scanTexture: SKTexture? = {
        let width: CGFloat = 1024.0
        let height: CGFloat = 100.0
        
        let shapeNode = SKShapeNode(rectOf: CGSize(width: width, height: 1.0))
        shapeNode.fillColor = .cyan
        shapeNode.strokeColor = .cyan
        
        shapeNode.glowWidth = height / 2.0
        
        shapeNode.alpha = 0.2
        
        return SKView.renderingView.texture(from: shapeNode, crop: CGRect(x: -width/2.0, y: -height/2.0, width: width, height: height))
    }()
    
    static let headCropTexture: SKTexture? = {
        let node = SKShapeNode(circleOfRadius: 36.0)
        node.fillColor = .white
        node.strokeColor = .white
        return SKView.renderingView.texture(from: node)
    }()
    
    static let headTopTexture: SKTexture? = {
        let node = SKSpriteNode(imageNamed: "head_top")
        node.zRotation = -0.5 * CGFloat.pi
        return SKView.renderingView.texture(from: node)
    }()
    
    static let zapRadius = 60.0 as CGFloat
    static func generateZapTexture() -> SKTexture? {
        let node = SKNode()
        
        func randomPoint() -> CGPoint {
            let angle = CGFloat(arc4random_uniform(360)) * CGFloat.pi / 180.0
            return CGPoint(
                x: zapRadius * cos(angle),
                y: zapRadius * sin(angle)
            )
        }
        
        var points = [CGPoint]()
        
        for _ in 0 ..< 5 {
            points.append(randomPoint())
        }
        
        
        for i in 0 ..< points.count {
            let a = points[i]
            let b = points[(i+1)%points.count]
            
            let path = UIBezierPath()
            path.move(to: a)
            path.bolt(to: b, smoothness: 4.0)
            
            let bolt = SKShapeNode(path: path.cgPath)
            bolt.lineWidth = 2.0
            bolt.fillColor = .clear
            bolt.strokeColor = #colorLiteral(red: 0.9105071188, green: 0, blue: 0, alpha: 1)
            bolt.glowWidth = 2.0
            
            node.addChild(bolt)
        
            let end = SKShapeNode(circleOfRadius: 0.5 * bolt.lineWidth)
            end.fillColor = bolt.strokeColor
            end.strokeColor = bolt.strokeColor
            
            end.position = a
            node.addChild(end)
        }
        
        return SKView.renderingView.texture(from: node)
    }
    
    private let zapTextures: [SKTexture] = {
        var textures = [SKTexture]()
        
        for _ in 0 ..< 20 {
            if let texture = ArtooDetooNode.generateZapTexture() {
                textures.append(texture)
            }
        }
        
        return textures
    }()
    
    static let armCoverTexture: SKTexture? = {
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 52.0, y: 0.0))
        path.addLine(to: CGPoint(x: 49.0, y: 8.0))
        path.addLine(to: CGPoint(x: 0.0, y: 8.0))
        path.close()
    
        let node = SKShapeNode(path: path.cgPath)
        node.fillColor = #colorLiteral(red: 0.9610359073, green: 0.9564498067, blue: 0.9730436206, alpha: 1)
        node.strokeColor = #colorLiteral(red: 0.9610359073, green: 0.9564498067, blue: 0.9730436206, alpha: 1)
        
        return SKView.renderingView.texture(from: node)
    }()

    public init() {
        headNode = SKSpriteNode(texture: ArtooDetooNode.headTexture)
        headNode.position.x = 2.0
        headNode.anchorPoint.x = 0.527
        headNode.zPosition = 0.2
        
        headTopNode = SKSpriteNode(texture: ArtooDetooNode.headTopTexture)
        headTopNode.anchorPoint.x = 0.38
        headTopNode.position.x = -4.0
        
        let headTopMaskNode = SKSpriteNode(texture: ArtooDetooNode.headCropTexture)
        let headTopCropNode = SKCropNode()
        headTopCropNode.position.x = 2.0
        headTopCropNode.zPosition = 0.1
        headTopCropNode.maskNode = headTopMaskNode
        headTopCropNode.addChild(headTopNode)
        
        lifeScannerNode.zRotation = -0.5 * CGFloat.pi
        lifeScannerNode.position.y = 17.0
        lifeScannerNode.position.x = 1.0
        lifeScannerNode.anchorPoint.x = 0.55
        headTopNode.addChild(lifeScannerNode)
        
        headPanelNode.zRotation = -0.5 * CGFloat.pi
        headPanelNode.position.y = 18.0
        headPanelNode.zPosition = 0.1
        headTopNode.addChild(headPanelNode)
        
        let body = SKPhysicsBody(circleOfRadius: 50.0)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = DeathStarEscapeScene.artooCategory
        body.collisionBitMask = DeathStarEscapeScene.wallCategory | DeathStarEscapeScene.stormtrooperCategory
        body.contactTestBitMask = DeathStarEscapeScene.stormtrooperCategory | DeathStarEscapeScene.doorCategory | DeathStarEscapeScene.endCategory | DeathStarEscapeScene.checkpointCategory
        
        let zapSize = 2.0 * ArtooDetooNode.zapRadius
        zapNode = SKSpriteNode(texture: nil, size: CGSize(width: zapSize, height: zapSize))
        
        super.init(texture: ArtooDetooNode.bodyTexture, color: .clear, size: ArtooDetooNode.bodyTexture?.size() ?? .zero)
        
        physicsBody = body
        addChild(headNode)
        addChild(headTopCropNode)
        zPosition = 5.0
        
        armNode.position.x = 15.0
        armNode.position.y = 12.0
        armNode.zRotation = -0.5 * CGFloat.pi
        addChild(armNode)
        
        let armCover = SKSpriteNode(texture: ArtooDetooNode.armCoverTexture)
        armCover.position.x = 10.0
        armCover.position.y = 12.0
        addChild(armCover)
        
        zapNode.run(.repeatForever(.animate(with: zapTextures, timePerFrame: 1.0 / 20.0)))
        zapNode.blendMode = .screen
        zapNode.zPosition = 1.0
    }
    
    private func setArmExtended(_ extended: Bool) {
        armNode.removeAllActions()
        
        let move = SKAction.moveTo(x: extended ? 58.0 : 15.0, duration: 0.3)
        move.timingFunction = TimingFunctions.cubicEaseInOut
        
        armNode.run(move)
    }
    
    public func contactBegan(withNode node: SKNode) {
        if let door = node as? DeathStarDoorNode {
            nearbyDoor = door
            
            if door.isPassable && !door.isHackedOpen {
                (scene as? DeathStarEscapeScene)?.speaker.speak(NSLocalizedString("deathStar.accessibility.r2d2NearDoor", value: "R2D2 is near a door. Stop moving to hack the door.", comment: ""))
            }
        }
        
        if let _ = node as? StormtrooperNode {
            if let scene = scene as? DeathStarEscapeScene {
                scene.artooWasCaptured(waitDuration: 4.0)
                scene.liveView?.connectedToy?.playAnimationBundle(R2D2Animations.surprised)
            }
        }
        
        if let body = node.physicsBody,
            let scene = self.scene as? DeathStarEscapeScene {
            
            if body.categoryBitMask & DeathStarEscapeScene.endCategory != 0 {
                reachEnd(node: node)
            } else if let checkpointNode = node as? DeathStarCheckpointNode {
                scene.checkpoint = node.position
                checkpointNode.isChecked = true
                
                scene.liveView?.connectedToy?.playSound(.excited, playbackMode: .playOnlyIfNotPlaying)
            }
        }
    }
    
    private func reachEnd(node: SKNode) {
        let goalLight = SKSpriteNode(imageNamed: "tileGoal")
        node.addChild(goalLight)
        goalLight.alpha = 0.0
        
        goalLight.run(.fadeIn(withDuration: 0.5))
        
        didReachEnd = true
        
        if let hackingScene = self.scene as? DeathStarHackingScene {
            moveToPosition(hackingNode: hackingScene.hackingPanelNode, withCode: hackingScene.code, relativeDestinationAngle: 0.5 * CGFloat.pi)
        } else {
            moveTo(endPosition: node.position)
        }
    }
    
    private func moveTo(endPosition: CGPoint) {
        let xDiff = endPosition.x - position.x
        let yDiff = endPosition.y - position.y
        let angle = atan2(yDiff, xDiff)
        
        let rotate1 = SKAction.rotate(toAngle: angle, duration: 0.4, shortestUnitArc: true)
        rotate1.timingFunction = TimingFunctions.cubicEaseInOut
        
        let move = SKAction.move(to: endPosition, duration: 0.4)
        move.timingFunction = TimingFunctions.cubicEaseInOut
        
        let rotate2 = SKAction.rotate(toAngle: 0.5 * CGFloat.pi, duration: 0.4, shortestUnitArc: true)
        rotate2.timingFunction = TimingFunctions.cubicEaseInOut
        
        let spin = SKAction.rotate(byAngle: -2.0 * CGFloat.pi, duration: 1.5)
        spin.timingFunction = TimingFunctions.cubicEaseInOut
    
        run(.sequence([rotate1, move, rotate2, spin])) { [weak self] in
            (self?.scene as? DeathStarEscapeScene)?.artooReachedEnd()
        }
        
        (scene as? DeathStarEscapeScene)?.liveView?.connectedToy?.playAnimationBundle(R2D2Animations.spin)
    }
    
    public func contactEnded(withNode node: SKNode) {
        if let door = nearbyDoor, door == node {
            nearbyDoor = nil
        }
    }
    
    public func startScanning() {
        if isScanning || isHacking { return }
        isScanning = true
        
        (scene as? DeathStarEscapeScene)?.speakOpenDirections()
    
        
        let rotationAngle = 170.0 / 180.0 * CGFloat.pi
        
        let easeInOut = TimingFunctions.cubicEaseInOut
        
        let shortLookDuration: TimeInterval = 1.0
        let longLookDuration: TimeInterval = 1.0
        
        let lookRight = SKAction.rotate(byAngle: -rotationAngle, duration: shortLookDuration)
        lookRight.timingFunction = easeInOut
        
        let lookRightToLeft = SKAction.rotate(byAngle: 2.0 * rotationAngle, duration: longLookDuration)
        lookRightToLeft.timingFunction = easeInOut
        
        let lookLeftToRight = SKAction.rotate(byAngle: -2.0 * rotationAngle, duration: longLookDuration)
        lookLeftToRight.timingFunction = easeInOut
        
        headNode.run(
            .sequence([
                lookRight,
                .repeatForever(
                    .sequence([ lookRightToLeft, lookLeftToRight ])
                )
            ]),
            withKey: ArtooDetooNode.scanActionKey
        )
        
        (scene as? DeathStarEscapeScene)?.enableStormtrooperIcons()
        
        headPanelNode.removeAllActions()
        lifeScannerNode.removeAllActions()
        
        headPanelNode.run(.group([
            .moveTo(y: 28.0, duration: 0.5),
            .scaleX(to: 0.15, duration: 0.5)
        ]))
        
        let rotateLeft = SKAction.rotate(toAngle: -0.3 * CGFloat.pi, duration: 0.75)
        let rotateRight = SKAction.rotate(toAngle: -0.7 * CGFloat.pi, duration: 0.75)
        rotateLeft.timingFunction = TimingFunctions.cubicEaseInOut
        rotateRight.timingFunction = TimingFunctions.cubicEaseInOut
        
        lifeScannerNode.run(.sequence([
            .wait(forDuration: 0.5),
            .repeatForever(
                .sequence([ rotateLeft, rotateRight ])
            )
        ]))
    }
    
    public func stopScanning() {
        if !isScanning { return }
        isScanning = false
    
        headNode.removeAction(forKey: ArtooDetooNode.scanActionKey)
        headNode.run(.rotate(toAngle: 0.0, duration: 0.5, shortestUnitArc: true))
        
        (scene as? DeathStarEscapeScene)?.disableStormtrooperIcons()
        
        
        headPanelNode.removeAllActions()
        lifeScannerNode.removeAllActions()
        
        headPanelNode.run(.group([
            .moveTo(y: 18.0, duration: 0.5),
            .scaleX(to: 1.0, duration: 0.5)
        ]))
        
        let rotate = SKAction.rotate(toAngle: -0.5 * CGFloat.pi, duration: 0.5)
        rotate.timingFunction = TimingFunctions.cubicEaseInOut
        lifeScannerNode.run(rotate)
    }
    
    private func moveToPosition(hackingNode: SKNode, withCode code: Int, relativeDestinationAngle: CGFloat) {
        isHacking = true
        
        let diffX = hackingNode.position.x - position.x
        let diffY = hackingNode.position.y - position.y
        
        let hackingAngle = hackingNode.zRotation + relativeDestinationAngle
        
        let doorDirectionX = cos(hackingAngle)
        let doorDirectionY = sin(hackingAngle)
        
        let dot = diffX * doorDirectionX + diffY * doorDirectionY
        let destinationAngle = relativeDestinationAngle + (dot > 0 ? hackingNode.zRotation : hackingNode.zRotation + CGFloat.pi)
        
        let desiredDistance = 90.0 as CGFloat
        
        let destinationPoint: CGPoint = CGPoint(
            x: hackingNode.position.x - copysign(doorDirectionX * desiredDistance, dot),
            y: hackingNode.position.y - copysign(doorDirectionY * desiredDistance, dot)
        )
        
        let angleToDestination = atan2(destinationPoint.y-position.y, destinationPoint.x-position.x)
        let backwardsAngleToDestination = angleToDestination + CGFloat.pi
        
        let angleDistance = abs(Double(angleToDestination-zRotation).canonizedAngle(fullTurn: 2.0 * Double.pi))
        let backwardsAngleDistance = abs(Double(backwardsAngleToDestination-zRotation).canonizedAngle(fullTurn: 2.0 * Double.pi))
        
        let movementAngle = angleDistance < backwardsAngleDistance ? angleToDestination : backwardsAngleToDestination
        
        let rotate1 = SKAction.rotate(toAngle: movementAngle, duration: 0.3, shortestUnitArc: true)
        let move = SKAction.move(to: destinationPoint, duration: 0.6)
        let rotate2 = SKAction.rotate(toAngle: destinationAngle, duration: 0.3, shortestUnitArc: true)
        rotate1.timingFunction = TimingFunctions.cubicEaseInOut
        move.timingFunction = TimingFunctions.cubicEaseInOut
        rotate2.timingFunction = TimingFunctions.cubicEaseInOut
        
        run(
            .sequence([
                .group([
                    move,
                    .sequence([rotate1, rotate2])
                ]),
                .run { [weak self] in
                    guard let `self` = self
                        else { return }
                
                    self.setArmExtended(true)
                },
                .wait(forDuration: 0.3),
                .run { [weak self] in
                    guard let scene = (self?.scene as? DeathStarEscapeScene)
                        else { return }
                    
                    scene.liveView?.sendMessageToContents(
                        .dictionary([
                            MessageKeys.type: MessageTypeId.hackingStart.playgroundValue(),
                            MessageKeys.code: .integer(code)
                        ])
                    )
                }
            ]),
            withKey: ArtooDetooNode.hackActionKey
        )
        
        guard let scene = self.scene as? DeathStarEscapeScene else { return }
        
        scene.lockNode?.show()
    }
    
    private func startHacking() {
        if isHacking || isScanning { return }
        
        guard let door = nearbyDoor
            else { return }
        
        moveToPosition(hackingNode: door, withCode: door.code, relativeDestinationAngle: 0.0)
    }
    
    private func stopHacking() {
        if !isHacking { return }
        isHacking = false
        
        removeAction(forKey: ArtooDetooNode.hackActionKey)
        setArmExtended(false)
        
        (scene as? DeathStarEscapeScene)?.lockNode?.hide()
    }
    
    public func enterDoorCode(_ code: Int) {
        guard let scene = self.scene as? DeathStarEscapeScene else { return }
    
        let hackingScene = scene as? DeathStarHackingScene
        
        let canHack = nearbyDoor != nil || (hackingScene != nil && didReachEnd)
    
        guard isHacking, canHack else {
            scene.liveView?.sendMessageToContents(
                .dictionary([
                    MessageKeys.type: MessageTypeId.hackingCancelled.playgroundValue()
                ])
            )
        
            return
        }
        
        let correctCode = nearbyDoor?.code ?? hackingScene?.code ?? 0
        
        if didReachEnd, let hackingScene = hackingScene {
            hackingScene.lockNode?.show(code: code, isCorrect: code == hackingScene.code)
        }
        else {
            nearbyDoor?.show(code: code)
        }
        
        if code == correctCode {
            run(playCorrectCodeSound)
            nearbyDoor?.isHackedOpen = true
            stopHacking()
            
            if didReachEnd, let hackingScene = hackingScene {
                moveTo(endPosition: hackingScene.maze.endLocation)
            }
        } else {
            run(playIncorrectCodeSound)
            run(.wait(forDuration: 0.10)) { [weak self] in
                guard
                    let `self` = self
                    else { return }
                
                let typeId: MessageTypeId = self.isHacking ? .hackingContinue : .hackingCancelled
                
                scene.liveView?.sendMessageToContents(
                    .dictionary([
                        MessageKeys.type: typeId.playgroundValue()
                    ])
                )
            }
        }
    }
    
    public func update() {
        // These rotate independently so that the top node can go behind the head to simulate 3D rotation.
        headTopNode.zRotation = headNode.zRotation
        
        guard
            let body = physicsBody,
            let scene = scene as? DeathStarEscapeScene
            else { return }
        
        if wasCaptured {
            stopHacking()
        }
        
        if wasCaptured || didReachEnd {
            stopScanning()
            body.velocity = .zero
            body.angularVelocity = 0.0
            return
        }
        
        var targetPosition: CGPoint? = nil
        
        if let direction = accessibilityDirection {
            targetPosition = CGPoint(x: position.x + 300.0 * direction.dx, y: position.y + 300.0 * direction.dy)
        } else if let currentTouch = currentTouch {
            targetPosition = currentTouch.location(in: scene)
        }
    
        if let targetPosition = targetPosition {
            
            let artooDiff = CGVector(dx: targetPosition.x - position.x, dy: targetPosition.y - position.y)
            let distance = hypot(artooDiff.dx, artooDiff.dy)
            
            if distance > 100.0 {
                speakTouchDirection(artooDiff)
            
                let direction = CGPoint(x: artooDiff.dx / distance, y: artooDiff.dy / distance)
                
                let maxArtooSpeed = UIAccessibilityIsVoiceOverRunning() ? 200.0 : 400.0 as CGFloat
                
                let artooSpeed = min(maxArtooSpeed, (distance - 100.0) * 4.0)
                
                body.velocity.dx = direction.x * artooSpeed
                body.velocity.dy = direction.y * artooSpeed
                
                rotate(towards: atan2(direction.y, direction.x), maxSpeed: 5.0 * CGFloat.pi)
                
                self.scanWaitStartTimestamp = nil
                
                stopScanning()
                stopHacking()
                return
            } else {
                speakTouchDirection(nil)
            }
        }
        
        body.velocity = .zero
        body.angularVelocity = 0.0
        
        let scanWaitStartTimestamp = self.scanWaitStartTimestamp ?? scene.currentTime
        self.scanWaitStartTimestamp = scanWaitStartTimestamp
        
        if scene.currentTime - scanWaitStartTimestamp >= 0.5 {
            if let door = nearbyDoor, door.isPassable && !door.isHackedOpen {
                startHacking()
            } else if isScanEnabled {
                startScanning()
            }
            self.scanWaitStartTimestamp = nil
        }
    }
    
    public func getZapped() {
        zapNode.alpha = 1.0
        zapNode.run(
            .sequence([
                .wait(forDuration: 0.5),
                .fadeOut(withDuration: 0.5)
            ]),
            withKey: "fade"
        )
        addChild(zapNode)
        
        if let toy = (scene as? DeathStarEscapeScene)?.liveView?.connectedToy {
            toy.playAnimationBundle(R2D2Animations.ionBlast)
        }
    }
    
    public func reset() {
        nearbyDoor = nil
        if zapNode.parent != nil {
            zapNode.removeFromParent()
        }
        isScanning = false
        zapNode.removeAction(forKey: "fade")
        armNode.position.x = 15.0
        didReachEnd = false
    }
    
    private func speakTouchDirection(_ direction: CGVector?) {
        guard let scene = self.scene as? DeathStarEscapeScene else { return }
    
        let description: String
    
        if let direction = direction {
            description = scene.description(forDirection: direction)
        } else {
            description = NSLocalizedString("deathStar.accessibility.stopDescription", value: "Stop", comment: "")
        }
        
        if description != currentTouchDirectionDescription {
            currentTouchDirectionDescription = description
            scene.speaker.speak(description, isVoiceOverOnly: true, pitch: 1.5)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
