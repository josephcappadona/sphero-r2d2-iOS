//
//  DeathStarMovementAssessmentController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-30.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public class DeathStarMovementAssessmentController: AssessmentController {
    public var onTouch: ((_ direction: Double, _ angle: Double) -> ())? = nil

    private var didSendCommand = false
    private var angle: Double = 0.0
    private var distance: Double = 0.0

    public func turnRight() {
        checkHighDistance()
        
        if angle > -10.0 {
            let hint = NSLocalizedString("deathStarMovement.assessment.badTurnRight", value: "Your code told R2-D2 to turn right but the `angle` variable was greater than `-10`. You should only call the `turnRight` function when the `angle` variable is less than `-10`.", comment: "Don't localize code between ticks (`angle`, `-10`, `turnRight`)")
            
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
        
        send(command: .TurnRight)
    }
    
    public func turnLeft() {
        checkHighDistance()
        
        if angle < 10.0 {
            let hint = NSLocalizedString("deathStarMovement.assessment.badTurnLeft", value: "Your code told R2-D2 to turn left but the `angle` variable was less than `10`. You should only call the `turnLeft` function when the `angle` variable is greater than `10`.", comment: "Don't localize code between ticks (`angle`, `10`, `turnLeft`)")
            
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
        
        send(command: .TurnLeft)
    }
    
    public func moveForward() {
        checkHighDistance()
        
        if abs(angle) > 10.0 {
            let hint = NSLocalizedString("deathStarMovement.assessment.badMoveForward", value: "Your code told R2-D2 to move forward but your finger wasn't in front of him. You should only call the `moveForward` function when the `angle` variable is between `-10` and `10`.", comment: "Don't localize code between ticks (`angle`, `10`, `-10`, `moveForward`)")
            
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
        
        send(command: .MoveForward)
    }
    
    private func checkHighDistance() {
        if distance < 50.0 {
            let hint = NSLocalizedString("deathStarMovement.assessment.lowDistanceCommand", value: "Your code gave R2-D2 a movement command, when your finger was too close to him! You should only call the `turnRight`, `turnLeft`, and `moveForward` functions when the `distance` variable is at least `50`.", comment: "Don't localize code between ticks (`turnRight`, `turnLeft`, `moveForward`, `distance`, `50`)")
        
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
    }

    private func send(command: MovementCommand) {
        if didSendCommand {
            let hint = NSLocalizedString("deathStarMovement.assessment.multipleCommands", value: "Your code gave R2-D2 multiple commands for the same touch! Make sure you call at most one of the `turnRight`, `turnLeft`, and `moveForward` functions.", comment: "Don't localize code between ticks (`turnRight`, `turnLeft` and `moveForward`)")
            
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        
            return
        }
        
        didSendCommand = true
    
        PlaygroundHelpers.sendMessageToLiveView(.dictionary([
            MessageKeys.type: MessageTypeId.artooMovementResponse.playgroundValue(),
            MessageKeys.command: .integer(command.rawValue)
        ]))
    }

    public override func onMessage(_ message: PlaygroundValue) {
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue()
            else { return }
    
        if typeId == MessageTypeId.artooMovementRequest.rawValue,
            let angle = dict[MessageKeys.angle]?.doubleValue(),
            let distance = dict[MessageKeys.distance]?.doubleValue() {
            
            didSendCommand = false
            self.angle = angle
            self.distance = distance
            
            onTouch?(distance, angle)
            
            if !didSendCommand {
                if distance > 50.0 {
                    let hint = NSLocalizedString("deathStarMovement.assessment.badNoMove", value: "Your finger was far away from R2-D2, but you didn't tell it to move! When the `distance` variable is greater than `50`, your code should call one of the `turnRight`, `turnLeft`, or `moveForward` functions.", comment: "Don't localize code between ticks (`distance`, `50`, `turnRight`, `turnLeft`, `moveForward`)")
                    
                    makeAssessment(status: .fail(hints: [hint], solution: nil))
                }
            
                send(command: .Nothing)
            }
        }
        
        if typeId == MessageTypeId.artooReachedEnd.rawValue {
            let message = NSLocalizedString("deathStarMovement.assessment.pass", value: "### Congratulations! \nYou successfully controlled R2-D2!\nOn to the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nYou successfully controlled R2-D2!\nOn to the [next page]'")
            makeAssessment(status: .pass(message: message))
        }
    }
}
