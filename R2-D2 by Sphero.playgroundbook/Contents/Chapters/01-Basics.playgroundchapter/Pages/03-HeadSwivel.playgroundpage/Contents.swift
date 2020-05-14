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
 **Goal:** Look side to side for danger.
 
 The escape pod lands with the Droids. R2-D2 must locate Obi-Wan Kenobi to deliver Princess Leia's message. With a host of questionable creatures and characters on Tatooine, R2-D2 follows the direct coordinates for Obi-Wan's whereabouts, looking out for signs of danger along the way.
 
 To control R2-D2’s dome, use the `setDomePosition` function. It accepts angles from -100 to 100 degrees. To make sure R2-D2 remains safe on his trek through Tatooine, change the dome position back and forth between these two values. After looking around, use the `play(sound:)` function to play a cautious sound.
 
 */
//#-hidden-code
import Foundation
import PlaygroundSupport
//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, userCode_HeadSwivel(), domeSwivel())
//#-code-completion(identifier, show, ., setDomePosition(angle:), play(sound:), wait(for:), R2D2Sound, happy, cautious, joyful, hello, excited, sad, scared, scan, talking)
func domeSwivel() {

}
//#-end-editable-code
//#-hidden-code
func userCode_HeadSwivel() {
//#-end-hidden-code

domeSwivel()
//#-hidden-code
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: HeadSwivelAssessmentController(), userCode: userCode_HeadSwivel)

//#-end-hidden-code
