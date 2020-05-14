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

let assessment = FinalMissionAssessmentController()

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

var isScanning: Bool {
    get {
        return assessment.isScanning()
    }
}

//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Get back to the ship.
 
The tractor beam has been disabled, but who knows for how long! Board the *Millennium Falcon* and prepare to flee the battle station for safety.
*/
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, assessment)
//#-code-completion(identifier, show, minCode, maxCode, doorState, newCode, /, if, ==, =, ., setDomePosition(angle:), wait(for:), while, isScanning, play(sound:), setStance(_:), R2D2Stance, R2D2Sound, happy, cautious, joyful, hello, excited, sad, scared, scan, talking, waddle, stop, bipod, tripod, else, <, >, <=, >=)
func stormtrooperNearby(distance: Double) {
    play(sound: distance < 800.0 ? .cautious : .happy)
    setStance(distance < 400.0 ? .waddle : .stop)
}

func scan() {
    while isScanning {
        play(sound: .scan)
        setDomePosition(angle: 100)
        wait(for: 1.0)
        play(sound: .scan)
        setDomePosition(angle: -100)
        wait(for: 1.0)
    }
    
    setDomePosition(angle: 0)
}

func hackDoor() {
    var minCode = 0
    var maxCode = 9999
    
    while doorState != .unlocked {
        let newCode = (minCode + maxCode) / 2
        
        enter(code: newCode)
        
        if doorState == .codeTooLow {
            minCode = newCode
        }
        
        if doorState == .codeTooHigh {
            maxCode = newCode
        }
    }
    
    play(sound: .joyful)
}

//#-hidden-code

assessment.hack = hackDoor
assessment.scan = scan
assessment.stormtrooperNearby = stormtrooperNearby
setupContent(assessment: assessment, userCode: {})
PlaygroundPage.current.needsIndefiniteExecution = true

//#-end-hidden-code
