//
//  DeathStarScene.swift
//  DeathStarEscape
//
//  Created by Anthony Blackman on 2017-06-21.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class DeathStarEscapeScene: SKScene, SKPhysicsContactDelegate {
    public static let wallCategory:         UInt32 = 0x01
    public static let artooCategory:        UInt32 = 0x02
    public static let stormtrooperCategory: UInt32 = 0x04
    public static let laserCategory:        UInt32 = 0x08
    public static let doorCategory:         UInt32 = 0x10
    public static let endCategory:          UInt32 = 0x20
    public static let checkpointCategory:   UInt32 = 0x40

    var stormtrooperNodes = [StormtrooperNode]()
    var scanNode: SKNode? = nil
    public var isRunning = false
    
    public let speaker = AccessibilitySpeechQueue()
    private var currentTouchDirectionDescription = ""
    
    open var maze: DeathStarMaze {
        get {
            return .finalMaze
        }
    }
    
    open var isScanEnabled: Bool {
        get {
            return true
        }
    }
    
    private var mapNode: MapNode? = nil
    public var lockNode: DeathStarLockNode? = nil
    
    public var scaledSize: CGSize {
        get {
            let cameraScale = camera?.xScale ?? 1.0
            return CGSize(width: size.width * cameraScale, height: size.height * cameraScale)
        }
    }
    
    var cameraContainerNode: MovementAveragingNode? = nil
    let artooNode = ArtooDetooNode()
    
    lazy var wallGridNode: ProximityGridNode = ProximityGridNode(followingNode: self.artooNode, maxDistance: 1024.0)
    
    var checkpoint: CGPoint? = nil
    
    public weak var liveView: DeathStarViewController?
    
    public private(set) var currentTime: TimeInterval = 0.0
    
    private var fadeNode: SKSpriteNode = {
        let screenBounds = UIScreen.main.bounds
        let maxScreenSize = max(screenBounds.width, screenBounds.height)
        
        let shapeNode = SKShapeNode(rectOf: CGSize(width: maxScreenSize, height: maxScreenSize))
        
        shapeNode.fillColor = .black
        shapeNode.strokeColor = .black
        
        let fadeNode = SKSpriteNode(texture: SKView.renderingView.texture(from: shapeNode))
        fadeNode.zPosition = 30.0
        
        return fadeNode
    }()
    
    public override init() {
        super.init(size: CGSize(width: 1024, height: 768))
        
        speaker.rate = 0.70
        
        reset()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func description(forDirection direction: CGVector) -> String {
        let angle = atan2(Double(direction.dy), Double(direction.dx))
        return (90.0 - angle * 180.0 / Double.pi).angleDescription()
    }
    
    public func speakOpenDirections() {
        var directionDescriptions = [String]()
        let directionDistance = DeathStarCell.size * 1.5
        
        for (dx,dy) in [(0,1), (1,0), (-1,0), (0,-1)] as [(CGFloat,CGFloat)] {
            let directionPoint = CGPoint(
                x: artooNode.position.x + dx*directionDistance,
                y: artooNode.position.y + dy*directionDistance
            )
            
            if maze.isVisible(point: directionPoint, fromPoint: artooNode.position) {
               
                directionDescriptions.append(description(forDirection: CGVector(dx: dx, dy: dy)))
            }
        }
        
        if directionDescriptions.count > 0 {
            speaker.speak(
                String(
                    format: NSLocalizedString("deathStar.accessibility.movementDirectionList", value: "Can move %@", comment: "%@ is replaced with a list of directions in which R2-D2 can move."),
                    directionDescriptions.joined(separator: " ")
                )
            )
        }
        
        var stormtrooperDistance = CGFloat.infinity
        var closestStormtrooperDiff = CGVector.zero
        
        for stormtrooper in stormtrooperNodes {
            
            let diff = CGVector(
                dx: stormtrooper.position.x - artooNode.position.x,
                dy: stormtrooper.position.y - artooNode.position.y
            )
            
            let distance = hypot(diff.dx, diff.dy)
            
            if distance < 500.0 && distance < stormtrooperDistance && maze.isVisible(point: stormtrooper.position, fromPoint: artooNode.position) {
                stormtrooperDistance = distance
                closestStormtrooperDiff = diff
            }
        }
        
        if stormtrooperDistance < 500.0 {
            speaker.speak(
                String(
                    format: NSLocalizedString("deathStar.accessibility.stormtrooperNearby", value: "Stormtrooper is %@, distance %d.", comment: "%@ is replaced with a direction (Forward, Left, etc), %d is replaced with a number."),
                    description(forDirection: closestStormtrooperDiff),
                    Int(stormtrooperDistance)
                )
            )
        } else if let bestDirection = maze.directionForPath(fromPoint: artooNode.position, toPoint: maze.endLocation) {
            
            let angle = atan2(Double(bestDirection.dy), Double(bestDirection.dx))
            
            let description = (90.0 - angle * 180.0 / Double.pi).angleDescription()
        
            speaker.speak(
                String(
                    format: NSLocalizedString("deathStar.accessibility.progressThroughMazeDirection", value: "Move %@ to progress", comment: "%@ is replaced with a direction (Left, Right, Forward, etc). \"Progress\" as in progress through the death star."),
                    description
                )
            )
        }
    }
    
    public func reset() {
        self.scaleMode = .resizeFill
        self.physicsWorld.gravity = .zero
        
        maze.reset()
        
        removeAllChildren()
        removeAllActions()
        
        stormtrooperNodes.removeAll()
        for stormtrooperPath in maze.stormtrooperPaths {
            let stormtrooper = StormtrooperNode(path: stormtrooperPath)
            stormtrooperNodes.append(stormtrooper)
            addChild(stormtrooper)
        }
        
        addChild(artooNode)
        artooNode.position = checkpoint ?? maze.startLocation
        if let artooDirection = maze.directionForPath(fromPoint: artooNode.position, toPoint: maze.endLocation) {
            artooNode.zRotation = atan2(artooDirection.dy, artooDirection.dx)
        } else {
            artooNode.zRotation = 0.0
        }
        artooNode.isScanEnabled = self.isScanEnabled
        artooNode.reset()
        
        wallGridNode.reset()
        for cell in maze.cells {
            if cell.wallType != .Filled {
                let wallNode = DeathStarWallNode(cell: cell)
                
                wallGridNode.addGridChild(node: wallNode)
            }
        }
        addChild(wallGridNode)
        
        let endNode = SKSpriteNode(imageNamed: "tileGoalTarget")
        endNode.position = maze.endLocation
        endNode.zPosition = 1.0
        
        let endBody = SKPhysicsBody(circleOfRadius: DeathStarCell.size)
        endBody.affectedByGravity = false
        endBody.isDynamic = false
        endBody.categoryBitMask = DeathStarEscapeScene.endCategory
        endNode.physicsBody = endBody
        
        wallGridNode.addGridChild(node: endNode)
        
        for checkpoint in maze.checkpoints {
            let isChecked: Bool
            if let spawnLocation = self.checkpoint, spawnLocation == checkpoint {
                isChecked = true
            } else {
                isChecked = false
            }
        
            let checkpointNode = DeathStarCheckpointNode(isChecked: isChecked)
            checkpointNode.position = checkpoint
            
            wallGridNode.addGridChild(node: checkpointNode)
        }
        
        let cameraContainer = MovementAveragingNode(initialPosition: artooNode.position, smoothness: 10)
        cameraContainerNode = cameraContainer
        addChild(cameraContainer)
        
        let cameraNode = SKCameraNode()
        cameraContainer.addChild(cameraNode)
        camera = cameraNode
        
        let mapNode = MapNode(maze: maze)
        self.mapNode = mapNode
        mapNode.zPosition = 21.0
        
        mapNode.addTrackedNode(artooNode, color: #colorLiteral(red: 0.3772626519, green: 0.6600916982, blue: 0.06266611069, alpha: 1), isScanned: false)
        mapNode.addTrackedNode(endNode, texture: SKTexture(imageNamed: "smallMapGoal"), isScanned: false)
        
        for stormtrooper in stormtrooperNodes {
            mapNode.addTrackedNode(stormtrooper, color: #colorLiteral(red: 0.9105071188, green: 0, blue: 0, alpha: 1), isScanned: true)
        }
        
        for doorConfig in maze.doorConfigurations {
            let door = DeathStarDoorNode(config: doorConfig)
            wallGridNode.addGridChild(node: door)
        }
        
        cameraContainer.addChild(mapNode)
        
        let lockNode = DeathStarLockNode()
        self.lockNode = lockNode
        mapNode.addChild(lockNode)
        
        if let falconLocation = maze.millenniumFalconLocation {
            let falconNode = SKSpriteNode(imageNamed: "falcon")
            falconNode.zPosition = 20.0
            falconNode.position = falconLocation
            falconNode.position.y += 240.0
            wallGridNode.addGridChild(node: falconNode)
        }
        
        updateCameraScale()
        
        self.backgroundColor = DeathStarWallNode.backgroundColor
        physicsWorld.contactDelegate = self
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if artooNode.currentTouch == nil,
            let touch = touches.first {
            artooNode.currentTouch = touch
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentTouch = artooNode.currentTouch,
            touches.contains(currentTouch) {
        
            artooNode.currentTouch = nil
        }
    }
    
    open func updateArtoo() {
        artooNode.update()
    }
    
    private var lastDistanceCategory = -1
    
    private func category(forDistance distance: CGFloat) -> Int {
        if distance < 400.0 { return 0 }
        else if distance < 800.0 { return 1 }
        else { return 2 }
    }
    
    public override func update(_ currentTime: TimeInterval) {
        self.currentTime = currentTime
        
        if !isRunning {
            physicsWorld.speed = 0.0
            speed = 0.0
            return
        }
        
        physicsWorld.speed = 1.0
        speed = 1.0
        
        updateArtoo()
        
        for stormtrooper in stormtrooperNodes {
            stormtrooper.update()
        }
        cameraContainerNode?.targetUpdated(position: artooNode.position)
        mapNode?.update(currentTime)
        
        wallGridNode.update()
        
        var minDistance = CGFloat.infinity
        for stormtrooper in stormtrooperNodes {
            let xDiff = stormtrooper.position.x - artooNode.position.x
            let yDiff = stormtrooper.position.y - artooNode.position.y
            
            let distance = hypot(xDiff, yDiff)
            
            minDistance = min(minDistance, distance)
        }
        
        let newCategory = category(forDistance: minDistance)
        
        if newCategory != lastDistanceCategory {
            lastDistanceCategory = newCategory
            
            liveView?.sendMessageToContents(
                .dictionary([
                    MessageKeys.type: MessageTypeId.stormtrooperDistance.playgroundValue(),
                    MessageKeys.distance: .floatingPoint(Double(minDistance))
                ])
            )
        }
    }
    
    public func enableStormtrooperIcons() {
        mapNode?.setScanning(true)
        
        liveView?.sendMessageToContents(.dictionary([
            MessageKeys.type: MessageTypeId.scanStart.playgroundValue()
        ]))
    }
    
    public func disableStormtrooperIcons() {
        mapNode?.setScanning(false)
        
        liveView?.sendMessageToContents(.dictionary([
            MessageKeys.type: MessageTypeId.scanStop.playgroundValue()
        ]))
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        
        guard let nodeA = contact.bodyA.node,
            let nodeB = contact.bodyB.node
            else { return }
        
        for (node,otherNode) in [(nodeA,nodeB), (nodeB,nodeA)] {
            if let laserNode = node as? LaserNode {
                laserNode.beganContact(withNode: otherNode)
            }
            
            if let doorNode = node as? DeathStarDoorNode {
                doorNode.contactBegan(withNode: otherNode)
            }
            
            if let artoo = node as? ArtooDetooNode {
                artoo.contactBegan(withNode: otherNode)
            }
        }
    }
    
    public func didEnd(_ contact: SKPhysicsContact) {
        
        guard let nodeA = contact.bodyA.node,
            let nodeB = contact.bodyB.node
            else { return }
    
        for (node,otherNode) in [(nodeA,nodeB), (nodeB,nodeA)] {
            if let doorNode = node as? DeathStarDoorNode {
                doorNode.contactEnded(withNode: otherNode)
            }
            
            if let artoo = node as? ArtooDetooNode {
                artoo.contactEnded(withNode: otherNode)
            }
        }
    }
    
    public func artooWasCaptured(waitDuration: TimeInterval) {
        if !artooNode.wasCaptured {
            artooNode.wasCaptured = true
            
            speaker.speak(NSLocalizedString("deathStar.accessibility.r2d2Captured", value: "R2D2 was captured by a stormtrooper.", comment: ""))
            
            let fadeDuration = 0.5
            let sleepDuration = max(0.0, waitDuration - fadeDuration)
            
            self.fadeNode.removeFromParent()
            camera?.addChild(fadeNode)
            fadeNode.alpha = 0.0
            
            fadeNode.run(
                .sequence([
                    .wait(forDuration: sleepDuration),
                    .fadeIn(withDuration: fadeDuration)
                ])
            ) { [weak self] in
                guard let `self` = self
                    else { return }
                
                self.artooNode.wasCaptured = false
                self.reset()
                
                self.fadeNode.removeFromParent()
                self.camera?.addChild(self.fadeNode)
                self.fadeNode.alpha = 1.0
                self.fadeNode.run(.fadeOut(withDuration: fadeDuration)) { [weak self] in
                    self?.fadeNode.removeFromParent()
                }
            }
        }
    }
    
    public func artooReachedEnd() {
        self.isRunning = false
        self.liveView?.sendMessageToContents(.dictionary([
            MessageKeys.type: MessageTypeId.artooReachedEnd.playgroundValue()
        ]))
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        updateCameraScale()
    }
    
    private func updateCameraScale() {
        let area = size.width * size.height
        
        let desiredArea = 1024.0 * 768.0 as CGFloat
        
        let cameraScale = sqrt(desiredArea / area)
        
        camera?.setScale(cameraScale)
        
        if let map = self.mapNode {
            let scaledSize = self.scaledSize
            
            let topSpace = liveView?.liveViewSafeAreaFrame.minY ?? 0.0 as CGFloat
            
            map.position.x = -0.5 * scaledSize.width + map.radius + 20.0
            map.position.y = 0.5 * scaledSize.height - map.radius - 20.0 - topSpace * cameraScale
            
        }
    }
}
