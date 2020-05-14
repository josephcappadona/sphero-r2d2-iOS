//
//  HackAssessmentController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-04.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

let contentHelperSetDomePosition = setDomePosition

public class HackAssessmentController: DeathStarAssessmentController {
    var codeEnteredCount = 0
    
    public override init() {
        super.init()
        
        scan = {
            while self.isScanning() {
                play(sound: .scan)
                contentHelperSetDomePosition(100)
                wait(for: 1.0)
                play(sound: .scan)
                contentHelperSetDomePosition(-100)
                wait(for: 1.0)
            }
            
            contentHelperSetDomePosition(0)
        }
    }

    open override func hackingFinished() {
        guard let state = self.state else { return }
    
        let doorCode = state.doorCode
   
        if let enteredCode = state.enteredCode {
            if enteredCode != doorCode {
                let hint = NSLocalizedString("hackingAssessment.notFinished", value: "Your code finished running but the door isn't unlocked yet! Make sure your code keeps running until the `doorState` variable is `.unlocked`.", comment: "Don't localize `doorState`, `.unlocked`")
                
                self.makeAssessment(status: .fail(hints: [hint], solution: nil))
                return
            }
        } else {
            let hint = NSLocalizedString("hackingAssessment.noCodesEntered", value: "Your code finished running but you didn't tell R2-D2 to enter any codes! Try calling `enter(code: newCode)` to enter a new code.", comment: "Don't localize `doorState`, `.unlocked`")
            
            self.makeAssessment(status: .fail(hints: [hint], solution: nil))
            return
        }
    }
    
    open override func codeEntered(_ code: Int) {
        codeEnteredCount += 1
    
        guard let state = self.state else { return }
        
        let doorCode = state.doorCode
        
        if let enteredCode = state.enteredCode, enteredCode == doorCode {
            let hint = NSLocalizedString("hackingAssessment.enterCodeDoorUnlocked", value: "Your code told R2-D2 to enter a code into an unlocked door! Make sure your code only tells R2-D2 to enter a code if the `doorState` variable is not equal to `.unlocked`.", comment: "Don't localize `doorState` or `.unlocked`")
            makeAssessment(status: .fail(hints: [hint], solution: nil))
            return
        }
        
        if let lowerBound = state.codeLowerBound, code <= lowerBound {
            let hint1Format = NSLocalizedString("hackingAssessment.codeBelowLowerBound1", value: "You told R2-D2 to enter the code `%.4d`, but it had already entered the code `%.4d` and found it was too low.", comment: "`%.4d` will be replaced with 4-digit numbers.")
            let hint1 = String(format: hint1Format, code, lowerBound)
            let hint2 = NSLocalizedString("hackingAssessment.codeBelowLowerBound2", value: "After entering a door code, if the `doorState` variable is `.codeTooLow`, try updating the `minCode` variable with the code you entered so that only higher codes will be entered afterwards.", comment: "Don't localize `doorState`, `.codeTooLow`, `minCode`.")
            makeAssessment(status: .fail(hints: [hint1, hint2], solution: nil))
            return
        }
        
        if let upperBound = state.codeUpperBound, code >= upperBound {
            let hint1Format = NSLocalizedString("hackingAssessment.codeAboveUpperBound1", value: "You told R2-D2 to enter the code `%.4d`, but it had already entered the code `%.4d` and found it was too high.", comment: "The two \"`%.4d`\"s will be replaced with 4-digit numbers.")
            let hint1 = String(format: hint1Format, code, upperBound)
            let hint2 = NSLocalizedString("hackingAssessment.codeAboveUpperBound2", value: "After entering a door code, if the `doorState` variable is `.codeTooHigh`, try updating the `maxCode` variable with the code you entered so that only lower codes will be entered afterwards.", comment: "Don't localize `doorState`, `.codeTooHigh`, `maxCode`.")
            makeAssessment(status: .fail(hints: [hint1, hint2], solution: nil))
            return
        }
    }
    
    open override func hackingStarted() {
        
        let startCodeEnteredCount = codeEnteredCount
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) { [weak self] in
            guard let `self` = self else { return }
            
            if self.codeEnteredCount == startCodeEnteredCount {
                let hint = NSLocalizedString("hackingAssessment.didNotEnterCode", value: "Your code didn't tell R2-D2 to enter a code! Try using the `enter(code:)` function.", comment: "Don't localize `enter(code:)`")
                self.makeAssessment(status: .fail(hints: [hint], solution: nil))
            }
        }
    }
}
