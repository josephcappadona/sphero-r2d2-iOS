//#-hidden-code
//
//  Contents.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-17.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//
import Foundation
import PlaygroundSupport
import UIKit

let assessment = HackAssessmentController()

enum DoorState {
    case unlocked
    case codeTooHigh
    case codeTooLow
    case codeNotEntered
}

var doorState: DoorState {
    get {
        guard let state = assessment.state else {
            return .unlocked
        }
    
        let doorCode = state.doorCode
        
        guard let enteredCode = state.enteredCode else {
            return .codeNotEntered
        }
        
        if enteredCode == doorCode {
            return .unlocked
        } else if enteredCode > doorCode {
            return .codeTooHigh
        } else {
            return .codeTooLow
        }
    }
}

func enter(code: Int) {
    assessment.enter(code: code)
}

//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Free the Rebels from the trash compactor.
 
 R2-D2 needs access to the Death Star’s systems in order to shut down the trash compactors. He can use the same command codes to open the doors. Hurry! The Rebels are in danger!
 
 Each door has a 4-digit combination, where each digit can be 0 - 9. You can tell R2-D2 to try combination with the `enter(code:)` function. After you enter a code, the `doorState` variable is updated.
 If it's `.codeTooLow`, then the code you entered was too low.
 If it's `.codeTooHigh`, then the code you entered was too high.
 If it's `.unlocked`, then congratulations, you've unlocked the door!
 
 In order to crack the code as fast as possible, your code will keep track of the lowest and highest possible access codes for the door using the `minCode` and `maxCode` variables.  When you enter a new code, use a code which is in between these two so that the number of possible access codes for the door is cut in half.  Then, update the `minCode` and `maxCode` variables depending on the result of entering the new code.
 
 Complete the function below so that R2-D2 can hack open doors, then use that ability to navigate through the Death Star. Find your way to the terminal to shut down the trash compactors.

*/
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, assessment)
//#-code-completion(identifier, show, minCode, maxCode, doorState, newCode, /, if, ==, =, .)
func hackDoor() {
    var minCode = 0
    var maxCode = 9999
    
    while doorState != .unlocked {
        let newCode = (minCode + maxCode) / 2

    }
}

//#-hidden-code

assessment.hack = hackDoor
setupContent(assessment: assessment, userCode: {})
PlaygroundPage.current.needsIndefiniteExecution = true

//#-end-hidden-code
