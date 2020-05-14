//#-hidden-code
//
//  Contents.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-17.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Warn Luke of the nearby danger.
 
 R2-D2's travels are deterred when the Droid is captured by Jawas and sold to Luke Skywalker and his Uncle Owen Lars. R2-D2 escapes in the night to continue the search for Obi-Wan Kenobi. When Luke and C-3PO discover R2-D2 is missing, they search the Tatooine sands, only to be followed by Sand People.
 
 R2-D2 hopes to warn Luke of the Tusken Raiders lurking in his path. Use the `setStance` function to make R2-D2 waddle and play a scared sound to alert Luke to danger.
 
 */
//#-hidden-code
import Foundation
import PlaygroundSupport
//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, setStance(_:), play(sound:), ., wait(for:), R2D2Stance, R2D2Sound, happy, cautious, joyful, hello, excited, sad, scared, scan, talking, waddle, stop, bipod, tripod)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, userCode_Waddle(), waddle())
func waddle() {

}
//#-end-editable-code
//#-hidden-code
func userCode_Waddle() {
//#-end-hidden-code

waddle()
//#-hidden-code
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: WaddleAssessmentController(), userCode: userCode_Waddle)
//#-end-hidden-code
