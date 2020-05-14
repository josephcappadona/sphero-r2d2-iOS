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

let assessment = StormtrooperAssessmentController()

//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Hide from Stormtroopers.
 
 Stormtroopers are on patrol in this sector. R2-D2 detects the Stormtroopers as they approach, helping it avoid detection on its way to the trash compactor.
 
 Complete `stormtrooperNearby` to make R2-D2 react to nearby Stormtroopers. The `distance` variable will confirm how close the nearest Stormtrooper is to R2-D2. If there are no Stormtroopers nearby, R2-D2 should play a happy sound. If a Stormtrooper is approaching, R2-D2 should play a scared sound. If a Stormtrooper is in very close proximity, R2-D2 should begin waddling.
*/
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, assessment, stormtrooperNearby)
//#-code-completion(identifier, show, play(sound:), setStance(_:), ., R2D2Stance, R2D2Sound, happy, cautious, joyful, hello, excited, sad, scared, scan, talking, waddle, stop, bipod, tripod, veryClose, close, if, else, <, >, <=, >=)
let veryClose = 400.0
let close = 800.0

func stormtrooperNearby(distance: Double) {

}

//#-hidden-code

assessment.stormtrooperNearby = stormtrooperNearby
setupContent(assessment: assessment, userCode: {})
PlaygroundPage.current.needsIndefiniteExecution = true

//#-end-hidden-code
