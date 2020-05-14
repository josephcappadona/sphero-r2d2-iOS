//
//  RollAssessmentController.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

import PlaygroundSupport

public final class RollAssessmentController: AssessmentController {
    
    private var isOnThreeLegs = false
    private var didRoll = false
    private var didWait = false
    private var didStop = false
    private var soundId: R2D2Sound?
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
        case .stance(let stance):
            isOnThreeLegs = stance == .tripod
            
        case .roll(speed: let speed, heading: let heading):
            if !isOnThreeLegs {
                let hint = NSLocalizedString("rollAssessment.noStance", value: "You told R2-D2 to roll before setting its stance! Try using the `setStance` function with `.tripod` so that R2-D2 is ready to roll!", comment: "Don't localize `setStance`, `.tripod`.")
                
                return .fail(hints: [hint], solution: nil)
            }
            
            if speed < 80 {
                let hint = NSLocalizedString("rollAssessment.tooSlow", value: "You told R2-D2 to roll with a very slow speed. Try increasing the speed of the `roll` function to be greater than 80.", comment: "Don't localize `roll`.")
                
                return .fail(hints: [hint], solution: nil)
            }
            
            didRoll = true
            didStop = false
            
        case .wait(seconds: let seconds):
            
            if didRoll {
                if seconds < 1.0 {
                    let hint = NSLocalizedString("rollAssessment.waitTooShort", value: "You waited for a very short amount of time after telling R2-D2 to roll. Try waiting for at least 1 second.", comment: "roll screen assessment, didn't wait long enough.")
                    
                    return .fail(hints: [hint], solution: nil)
                }
                
                didWait = true
            }
            
        case let .playSound(sound: sound):
            guard sound == .happy else {
                return .fail(hints: [NSLocalizedString("rollAssessment.wrongSound", value: "You correctly played a sound, but it wasn't happy. R2-D2 should be happy when it reaches the escape pod!", comment: "Roll assessment fail, wrong sound played")], solution: nil)
            }
            soundId = sound
            
        case .stopRoll(heading: _):
            if didRoll {
                didStop = true
                
                if !didWait {
                    let hint = NSLocalizedString("rollAssessment.noWait", value: "You told R2-D2 to stop rolling right after telling it to start rolling. You need to give it some time to roll! Try using the `wait` function to wait for 1 second before telling R2-D2 to stop.", comment: "Don't localize `wait`.")
                    
                    return .fail(hints: [hint], solution: nil)
                }
            }
            
        case .userCodeFinished:
            if !didRoll {
                let hint = NSLocalizedString("rollAssessment.noRoll", value: "Your code didn't tell R2-D2 to roll! Try using the `roll` function.", comment: "Don't localize `roll`")
                return .fail(hints: [hint], solution: nil)
            }
            
            if !didStop {
                let hint = NSLocalizedString("rollAssessment.noStop", value: "Your code told R2-D2 to start rolling, but never told it to stop! Try using the `stopRoll` function to stop R2-D2 from rolling forever!", comment: "Don't localize `stopRoll`.")
                return .fail(hints: [hint], solution: nil)
            }
            
            if soundId == nil {
                return .fail(hints: [NSLocalizedString("rollAssessment.noSoundFail", value: "You need to play a sound on R2-D2 when it reaches the escape pod. Use the `play(sound:)` function to play a happy sound.", comment: "Roll assessment fail, no sound played")], solution: nil)
            }
            
            PlaygroundHelpers.sendMessageToLiveView(.dictionary([
                MessageKeys.type: MessageTypeId.showEscapePod.playgroundValue()
                ]))
            
            let message = NSLocalizedString("rollAssessment.pass", value: "### Congratulations! \nR2-D2 reached the escape pod!\nOn to the [next page](@next).", comment: "## is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nR2-D2 reached the escape pod!\nOn to the [next page]'")
            return .pass(message: message)
            
        default: break
        }
        
        return nil
    }
    
}
