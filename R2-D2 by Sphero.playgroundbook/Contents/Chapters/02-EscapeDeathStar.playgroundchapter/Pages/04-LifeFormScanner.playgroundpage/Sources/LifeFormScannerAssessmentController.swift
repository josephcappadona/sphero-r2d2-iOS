//
//  LifeFormScannerAssessmentController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-30.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public class DeathStarScanAssessmentController: DeathStarAssessmentController {
    
    private var headPosition: Double = 0.0
    private var didChangeHeadPosition = false
    private var didPlaySound = false
    
    open override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        if !isScanning() {
            return nil
        }
    
        switch event.data {
            case .headPosition(angle: let newHeadPosition):
            
                if didChangeHeadPosition {
                    let hint1 = NSLocalizedString("scanAssessment.noWait1", value: "You set R2-D2's dome position twice without waiting. R2-D2 needs time to move its dome to the first position before moving it to a new position.", comment: "")
                    let hint2 = NSLocalizedString("scanAssessment.noWait2", value: "Make sure you always call the `wait` function in between calls to the `setDomePosition` function.", comment: "Don't localize `wait`, `setDomePosition`")
                    
                    return .fail(hints: [hint1, hint2], solution: nil)
                }
                
                if abs(newHeadPosition - 100.0) > 1.0 && abs(newHeadPosition + 100.0) > 1.0 {
                    let hintFormat = NSLocalizedString("scanAssessment.wrongAngle1", value: "You set R2-D2's dome position to `%.1f`. You should alternate between setting it to `100.0` and `-100.0`.", comment: "`%.1f` is replaced with a decimal number. Don't localize `100.0` and `-100.0`, ie 'You set R2-D2 head position to `140`...")
                    let hint = String(format: hintFormat, newHeadPosition)
                    return .fail(hints: [hint], solution: nil)
                }
                
                if (headPosition < 0 && newHeadPosition < 0) || (headPosition > 0 && newHeadPosition > 0) {
                    let hintFormat = NSLocalizedString("scanAssessment.wrongAngle2", value: "You set R2-D2's dome position to `%.1f`, then set it to `%.1f`. You should alternate between setting it to `100.0` and `-100.0`.", comment: "`%.1f` is replaced with a decimal number. Don't localize `100.0` and `-100.0`. ie: You set R2-D2's head position to `140`, then set it to `-150`.")
                    let hint = String(format: hintFormat, headPosition, newHeadPosition)
                    return .fail(hints: [hint], solution: nil)
                }
                
                headPosition = newHeadPosition
                didChangeHeadPosition = true
            
                break
            case .wait(seconds: let seconds):
            
                if !didChangeHeadPosition {
                    let hint = NSLocalizedString("scanAssessment.noHeadChange", value: "Your code waited without telling R2-D2 to rotate its dome! Make sure your code sets R2-D2's dome position before waiting.", comment: "scan assessment, didn't change dome position befor waiting")
                    return .fail(hints: [hint], solution: nil)
                }
                
                if !didPlaySound {
                    let hint = NSLocalizedString("scanAssessment.noSound", value: "Your code waited without telling R2-D2 to play a sound! Make sure your code tells R2-D2 to play the scan sound before waiting.", comment: "scan assessment, didn't play a sound before waiting")
                    return .fail(hints: [hint], solution: nil)
                }
                
                if abs(seconds - 1.0) > 0.1 {
                    let hintFormat = NSLocalizedString("scanAssessment.wrongWait", value: "You waited `%.2f` seconds between setting R2-D2's dome position. Make sure your code always waits for exactly 1 second.", comment: "`%.2f` is replaced with a decimal number.")
                    let hint = String(format: hintFormat, seconds)
                    return .fail(hints: [hint], solution: nil)
                }
            
                didPlaySound = false
                didChangeHeadPosition = false
            
            case .playSound(sound: let sound):
                if didPlaySound {
                    let hint = NSLocalizedString("scanAssessment.noWaitSound", value: "You told R2-D2 to play two sounds without waiting in between them! Make sure your code always waits between playing sounds.", comment: "scan assessment, didn't wait between sounds")
                    
                    return .fail(hints: [hint], solution: nil)
                }
                
                if sound != .scan {
                    let hint = NSLocalizedString("scanAssessment.wrongSound", value: "You told R2-D2 to play a sound, but it wasn't the scanning sound!", comment: "scan assessment, wrong sond played")
                    
                    return .fail(hints: [hint], solution: nil)
                }
            
                didPlaySound = true
            
            default:
                break
        }
        
        return nil
    }
    
    
    open override func scanningStarted() {
        headPosition = 0.0
        didChangeHeadPosition = false
        didPlaySound = false
    }
    
    open override func scanningFinished() {
        if isScanning() {
            let hint1 = NSLocalizedString("scanAssessment.userCodeFinished", value: "Your code finished running, but R2-D2 is still scanning!", comment: "")
            let hint2 = NSLocalizedString("scanAssessment.userCodeFinished", value: "Use a `while` loop on the `isScanning` variable to make your code keep running as long as R2-D2 is scanning.", comment: "Don't localize `while` and `isScanning`")
            makeAssessment(status: .fail(hints: [hint1, hint2], solution: nil))
        }
    }
}

