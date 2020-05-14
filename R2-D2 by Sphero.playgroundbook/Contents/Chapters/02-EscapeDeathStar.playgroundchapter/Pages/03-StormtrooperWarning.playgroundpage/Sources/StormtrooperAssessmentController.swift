//
//  StormtrooperAssessmentController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-30.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public class StormtrooperAssessmentController: DeathStarAssessmentController {
    
    var stormtrooperDistance: Double = 0.0
    var playedSound: Bool = false
    
    var currentStance: StanceCommand.StanceId = .stop

    open override func onStormtrooperNearby(distance: Double) {
        stormtrooperDistance = distance
        playedSound = false
    }
    open override func onStormtrooperCodeFinished() {
        if !playedSound {
            let hint = NSLocalizedString("stormtrooperAssessment.noSound", value: "Your code didn't tell R2-D2 to make a sound! Make sure that your code always tells R2-D2 to play a sound.", comment: "stormtrooper assessment fail, didn't play a sound")
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
        
        if stormtrooperDistance > 400 && currentStance != .stop {
            let hint = NSLocalizedString("stormtrooperAssessment.noStop", value: "There weren't any stormtroopers very close to R2-D2, but your code didn't tell it to stop wadding! Make sure you tell R2-D2 to stop wadding when a stormtrooper's distance is greater than `400`.", comment: "Don't localize `400`.")
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
        
        if stormtrooperDistance < 400 && currentStance != .waddle {
            let hint = NSLocalizedString("stormtrooperAssessment.noWaddle", value: "There was a stormtrooper very close to R2-D2, but your code didn't tell it to waddle! Make sure you tell R2-D2 to waddle when a stormtrooper's distance is less than `400`.", comment: "Don't localize `400`.")
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
    }
    
    open override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
            case .playSound(sound: let sound):
                playedSound = true
            
                if stormtrooperDistance < 800 && sound != .scared {
                    let hint = NSLocalizedString("stormtrooperAssessment.notScaredSound", value: "There was a stormtrooper nearby, but the sound you told R2-D2 to play wasn't a scared sound! Make sure you have R2-D2 play a scared sound if a stormtrooper's distance is less than `800` units.", comment: "Don't localize `800`")
                    return .fail(hints: [hint], solution: nil)
                }
            
                if stormtrooperDistance > 800 && sound != .happy {
                    let hint = NSLocalizedString("stormtrooperAssessment.notHappySound", value: "There weren't any stormtroopers nearby, but the sound you told R2-D2 to play wasn't a happy sound! Make sure you have R2-D2 play a happy sound if a stormtrooper's distance is greater than `800` units.", comment: "Don't localize `800`")
                    return .fail(hints: [hint], solution: nil)
                }
            
            case .stance(let stance):
                currentStance = stance
            
            default:
                break
            
        }
        
        return nil
    }
}
