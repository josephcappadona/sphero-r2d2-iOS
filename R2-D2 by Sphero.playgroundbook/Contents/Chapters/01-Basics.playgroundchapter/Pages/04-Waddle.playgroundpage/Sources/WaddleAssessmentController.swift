//
//  WaddleAssessmentController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import PlaygroundSupport
import Foundation

public class WaddleAssessmentController: AssessmentController {

    private var didWaddle = false
    private var didWait = false
    private var didStop = false
    private var didPlaySound = false

    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
            case .stance(let stance):
                if stance == .waddle {
                    didWaddle = true
                } else {
                    if didWaddle {
                        if !didWait {
                            let hint = NSLocalizedString("waddleAssessment.noWait", value: "You told R2-D2 to stop waddling immediately after telling its to waddle! Give it some time to waddle using the `wait` function.", comment: "Don't localize `wait`.")
                            return .fail(hints: [hint], solution: nil)
                        }
                        didStop = true
                    }
                }
                break
            
            case .wait(seconds: let seconds):
                if didWaddle && !didWait {
                    if seconds < 3 {
                        let hint = NSLocalizedString("waddleAssessment.waitTooShort", value: "R2-D2 needs time to waddle. Make sure you wait for at least 3 seconds to let it waddle.", comment: "")
                        return .fail(hints: [hint], solution: nil)
                    }
                
                    didWait = true
                }
            
            case .playSound(sound: let sound):
                if sound == .scared {
                    didPlaySound = true
                } else {
                    let hint = NSLocalizedString("waddleAssessment.wrongSound", value: "R2-D2 is scared, so it should make a scared sound. Try using the `.scared` sound in the `play(sound:)` function.", comment: "Don't localize `.scared`, `play(sound:)`.")
                    return .fail(hints: [hint], solution: nil)
                }
            
            case .userCodeFinished:
                if !didWaddle {
                    let hint = NSLocalizedString("waddleAssessment.noWaddle", value: "You didn't tell R2-D2 to waddle! Try using the `setStance` function to set R2-D2's stance to `.waddle`.", comment: "Don't localize `setStance`, `.waddle`")
                    return .fail(hints: [hint], solution: nil)
                }
            
                if !didStop {
                    let hint = NSLocalizedString("waddleAssessment.noStop", value: "You didn't tell R2-D2 to stop waddling! Try setting R2-D2's stance to `.stop` after telling it to waddle.", comment: "Don't localize `.stop`.")
                    return .fail(hints: [hint], solution: nil)
                }
                
                if !didPlaySound {
                    let hint = NSLocalizedString("waddleAssessment.noSound", value: "R2-D2 needs to make a sound to get the others' attention! Try making a scared sound.", comment: "")
                    return .fail(hints: [hint], solution: nil)
                }
            
                return .pass(message: NSLocalizedString("waddleAssessment.pass", value: "### Congratulations!\nR2-D2 made enough noise to get the others' attention and got away!\nOn to the [next page](@next).", comment: "### is bold indicator, @(next) is a hyperlink, [] indicates what should be hyperlinked. Localize `Congratulations\nR2-D2 made enough nose to get the others' attention and got away!\nOn to the [next page]."))
            
            default: break
        }
        
        return nil
    }
}
