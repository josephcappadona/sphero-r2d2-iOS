//
//  DeathStarMovementViewController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-30.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

public enum MovementCommand: Int {
    case Nothing = 1
    case MoveForward = 2
    case TurnRight = 3
    case TurnLeft = 4
}

@objc (DeathStarMovementViewController)
public class DeathStarMovementViewController: DeathStarViewController {
    
    @IBOutlet weak var middleArtooConstraint: NSLayoutConstraint!
    
    open override class var scene: DeathStarEscapeScene {
        get {
            return DeathStarMovementScene()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundContainer?.accessibilityLabel = NSLocalizedString("movement.accessibility.label", value: "R2D2 is in the hanger bay in front of the Millennium Falcon.", comment: "movement screen, image accessibility. image is of r2-d2 in a hanger bay by the Millennium Falcon.")
    }
    
    open override func onReceive(message: PlaygroundValue) {
        super.onReceive(message: message)
        
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue(),
            typeId == MessageTypeId.artooMovementResponse.rawValue,
            let commandId = dict[MessageKeys.command]?.intValue(),
            let command = MovementCommand(rawValue: commandId),
            let movementScene = self.scene as? DeathStarMovementScene
            else { return }
        
        movementScene.currentCommand = command
        movementScene.isWaitingForMessage = false
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        guard let scene = scene as? DeathStarMovementScene else { return }
        
        scene.currentCommand = .Nothing
        scene.isWaitingForMessage = false
        
        connectedToy?.setStance(.tripod)
    }

    public override func sendToyReadyMessage() {
        super.sendToyReadyMessage()
        
        connectedToy?.setStance(.tripod)
    }

}

public class DeathStarMovementScene: DeathStarEscapeScene {
    open override var maze: DeathStarMaze {
        get {
            return .movementMaze
        }
    }
    
    open override var isScanEnabled: Bool {
        get {
            return false
        }
    }
    
    let framesPerToyCommand = 10
    var framesUntilNextToyCommand = 0
    
    var currentCommand = MovementCommand.Nothing
    var isWaitingForMessage = false
    
    open override func updateArtoo() {
        if artooNode.currentTouch == nil {
            currentCommand = .Nothing
        }
    
        moveArtoo()
        
        if let touch = artooNode.currentTouch, !isWaitingForMessage {
            
            let touchLocation = touch.location(in: self)
            
            let xDiff = touchLocation.x - artooNode.position.x
            let yDiff = touchLocation.y - artooNode.position.y
            
            let distance = Double(hypot(xDiff, yDiff))
            
            let absoluteRadians = atan2(yDiff, xDiff)
            let relativeRadians = absoluteRadians - artooNode.zRotation
            let relativeDegrees = Double(relativeRadians * 180.0 / CGFloat.pi).canonizedAngle()
            
            let message = PlaygroundValue.dictionary([
                MessageKeys.type: MessageTypeId.artooMovementRequest.playgroundValue(),
                MessageKeys.angle: .floatingPoint(relativeDegrees),
                MessageKeys.distance: .floatingPoint(distance)
            ])
            
            isWaitingForMessage = true
            
            liveView?.sendMessageToContents(message)
        }
    }
    
    private func moveArtoo() {
        guard let body = artooNode.physicsBody else { return }
        
        if artooNode.didReachEnd {
            body.velocity = .zero
            body.angularVelocity = 0.0
            return
        }
    
        if currentCommand == .Nothing {
            body.velocity = .zero
        } else {
            let speed = 300.0 as CGFloat
            body.velocity = CGVector(
                dx: cos(artooNode.zRotation) * speed,
                dy: sin(artooNode.zRotation) * speed
            )
        }
    
        switch currentCommand {
            case .Nothing:
                body.angularVelocity = 0.0
            
            case .MoveForward:
                body.angularVelocity = 0.0
            
            case .TurnLeft:
                body.angularVelocity = 2.0 * CGFloat.pi
            
            case .TurnRight:
                body.angularVelocity = -2.0 * CGFloat.pi
        }
        
        if framesUntilNextToyCommand == 0 {
            let rotationAngle = Double(90.0 - artooNode.zRotation * 180.0 / CGFloat.pi)
            liveView?.connectedToy?.rotateAim(rotationAngle)
            framesUntilNextToyCommand = framesPerToyCommand
        }
        
        framesUntilNextToyCommand -= 1
    }
}
