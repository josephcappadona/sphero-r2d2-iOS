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
 **Goal:** Connect to R2-D2 and escape.
 
 Princess Leia has trusted R2-D2 with the Death Star plans as the ship is being boarded by Imperial forces. As Stormtroopers move in, patrolling the Rebel ship, help R2-D2 find its way to C-3PO and the escape pod.
 
 Make sure R2-D2 is ready to roll by using the `setStance` function to position his third foot for drive mode. Use the `roll` and `wait` functions to get R2-D2 safely back to the escape pod. Once the Droid has arrived, use the play function to play a happy sound.
 
 To connect your iPad to R2-D2, hold them near each other. Make sure Bluetooth is on and your app-enabled R2-D2 Droid is fully charged. Tap `Connect Droid` and tap your Droid in the list to connect.
 
 If you’d like to start over, tap ![More](threeDots.png "More") in the top right, and then select *Reset Page*.

 */
//#-hidden-code
import Foundation
import PlaygroundSupport

var setStanceLocal = setStanceImpl

setStanceImpl = { stance in
    setStanceLocal(stance)
    wait(for: 2.0)
}

//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, userCode_Roll(), roll(), setStanceImpl, setStanceLocal)
//#-code-completion(identifier, show, ., setStance(_:), play(sound:), stopRoll(), wait(for:), roll(heading:speed:), R2D2Stance, waddle, stop, bipod, tripod, R2D2Sound, happy, cautious, joyful, hello, excited, sad, scared, scan, talking)
func escape() {

}
//#-end-editable-code
//#-hidden-code
func userCode_Roll() {
//#-end-hidden-code

escape()
//#-hidden-code
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: RollAssessmentController(), userCode: userCode_Roll)

//#-end-hidden-code
