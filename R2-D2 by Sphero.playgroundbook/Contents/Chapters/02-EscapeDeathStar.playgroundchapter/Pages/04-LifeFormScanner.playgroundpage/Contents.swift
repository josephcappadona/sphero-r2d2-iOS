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

let assessment = DeathStarScanAssessmentController()

var isScanning: Bool {
    get {
        return assessment.isScanning()
    }
}

//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Scan for Stormtroopers.
 
 R2-D2 continues to dodge Stormtroopers in pursuit of rescuing the Rebels from the trash compactor. While scanning the hallways, R2-D2 can use his life form scanner to see if there are more Stormtroopers nearby.
 
 Complete the `scan` function to scan for nearby Stormtroopers. Using a `while` loop, check the `isScanning` to see if R2-D2 should be scanning. If he should be, rotate R2-D2's dome back and forth between `-100` and `100` degrees. Make sure to play a ‘scan’ sound and wait between changing the dome positions.
 
 */
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, assessment, scan())
//#-code-completion(identifier, show, isScanning, setDomePosition(angle:), wait(for:), while, play(sound:), ., R2D2Sound, happy, cautious, joyful, hello, excited, sad, scared, scan, talking)
func scan() {

}

//#-hidden-code

assessment.scan = scan
setupContent(assessment: assessment, userCode: {})
PlaygroundPage.current.needsIndefiniteExecution = true
//#-end-hidden-code
