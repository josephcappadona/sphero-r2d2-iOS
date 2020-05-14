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

let assessment = DeathStarMovementAssessmentController()

func turnRight() {
    assessment.turnRight()
}

func turnLeft() {
    assessment.turnLeft()
}

func moveForward() {
    assessment.moveForward()
}

//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Find the trash compactor to free the Rebels.
 
 After the *Millennium Falcon's* capture on the Death Star, Han Solo and Luke Skywalker ambush a pair of Stormtroopers, steal their uniforms and police the ship to locate a detained Princess Leia. R2-D2 and C-3PO are told to watch the *Millennium Falcon*. When Luke, Han and Leia escape the detention cell, but end up in the trash compactor, R2-D2 is summoned to help them escape!
 
 You will use your finger to guide R2-D2 through the Death Star. Complete the `onTouch` function to move R2-D2 in the correct direction. `onTouch` has two parameters. `distance` is how far your finger is away from R2-D2 and `angle` is the angle between where R2-D2 is facing and your finger. First check if `distance` is large enough to start a roll command. Then check compare `angle` to `angleThreshold` to determine if you should call `moveForward`, `turnLeft`, or `turnRight`.

*/
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, assessment, onTouch(distance:angle:))
//#-code-completion(identifier, show, distance, distanceThreshold, angle, angleThreshold, >, <, >=, <=, turnLeft(), turnRight(), moveForward(), if, else)
let distanceThreshold = 50.0
let angleThreshold = 10.0

func onTouch(distance: Double, angle: Double) {
    if distance > distanceThreshold {

    }
}

//#-hidden-code

assessment.onTouch = onTouch
setupContent(assessment: assessment, userCode: {})
PlaygroundPage.current.needsIndefiniteExecution = true

//#-end-hidden-code
