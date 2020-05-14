//
//  HeadSwivelAssessmentController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public final class HeadSwivelAssessmentController: AssessmentController {
    
    private var firstHeadPosition: Double?
    private var secondHeadPosition: Double?
    private var currentHeadPosition = 0.0
    private var didChangeHeadPosition = false
    private var soundId: R2D2Sound?
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
        case let .headPosition(angle: newHeadPosition):
            
            if didChangeHeadPosition {
                return .fail(hints: [NSLocalizedString("headSwivelAssessmentFail.noWait", value: "You told R2-D2 to change dome positions right after setting the first one. You need to give it some time to change dome positions! Try using the `wait` function to wait for at least 1 second.", comment: "head swivel assessment fail, no wait")], solution: nil)
            }
            
            if abs(newHeadPosition - 100.0) > 1.0 && abs(newHeadPosition + 100.0) > 1.0 {
                return .fail(hints: [String(format: NSLocalizedString("headSwivelAssessmentFail.badFirstAngle", value: "You set R2-D2's dome position to `%.1f`. You should alternate between setting it to `100.0` and `-100.0`.", comment: "head swivel assessment fail, wrong starting angle, %.1f is a number "), newHeadPosition)], solution: nil)
            }
            
            if (currentHeadPosition < 0.0 && newHeadPosition < 0.0) || (currentHeadPosition > 0.0 && newHeadPosition > 0.0) {
                return .fail(hints: [NSLocalizedString("headSwivelAssessmentFail.badSecondAngle", value: "R2-D2's dome can go from `-100` to `100` degrees. It needs to check all around him, so you need to alternate between `-100` and `100`.", comment: "head swivel assessment fail, wrong ending angle")], solution: nil)
            }
            
            if let firstHeadPosition = firstHeadPosition {
                secondHeadPosition = newHeadPosition
            } else {
                firstHeadPosition = newHeadPosition
            }
            
            currentHeadPosition = newHeadPosition
            
        case .wait(seconds: _):
            didChangeHeadPosition = false
            
        case let .playSound(sound: sound):
            guard sound == .cautious else {
                return .fail(hints: [NSLocalizedString("headSwivelAssessmentFail.wrongSound", value: "You correctly played a sound, but it wasn't cautious. R2-D2 should be cautious when it is scanning the desert!", comment: "head swivel assessment fail, wrong sound played")], solution: nil)
            }
            soundId = sound
            
        case .userCodeFinished:
            if firstHeadPosition == nil {
                return .fail(hints: [NSLocalizedString("headSwivelAssessmentFail.noHeadPosition", value: "Your code never changed R2-D2's dome position. Try using the `setDomePosition` function.", comment: "head swivel assessment fail, no dome position was set")], solution: nil)
            }
            
            if secondHeadPosition == nil {
                return .fail(hints: [NSLocalizedString("headSwivelAssessmentFail.noSecondHeadPosition", value: "R2-D2 is trying to scan the desert. It's dome needs to rotate back and forth. Try adding another `setDomePosition` command.", comment: "head swivel assessment fail, no second dome position was set")], solution: nil)
            }
            
            if soundId == nil {
                return .fail(hints: [NSLocalizedString("headSwivelAssessmentFail.noSound", value: "You need to play a sound while R2-D2 is scanning. Use the `play(sound:)` function to play a cautious sound.", comment: "head swivel assessment fail, no sound played")], solution: nil)
            }
         
            let message = NSLocalizedString("headSwivelAssessment.pass", value: "### Congratulations! \nR2-D2 successfully scanned for danger!\nOn to the [next page](@next).", comment: "## is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nR2-D2 successfully scanned for danger!\nOn to the [next page]'")
            return .pass(message: message)
            
        default:
            break
        }
 
        return nil
    }
    
}

