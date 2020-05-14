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
 **Goal:** Deliver the message to Obi-Wan Kenobi.
 
 We found Obi-Wan Kenobi! With Luke Skywalker's help, R2-D2 located Obi-Wan Kenobi. R2-D2 plays the message from Princess Leia as a hologram.
 
 Use R2-D2's light displays to communicate the message. Turn the dome’s main lights using the `setFrontPSILed` and `setBackPSILed` functions, and play a talking sound using the `play(sound:)` function.  Fill in the `flashLights` function to turn the holoprojector and logic display lights on and off using the `setHoloProjectorLed` and `setLogicDisplayLeds` functions. Call the `flashLights` function multiple times to finish his message!

 */
//#-hidden-code
import Foundation
import PlaygroundSupport

let assessmentController = LightsAssessmentController()



//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, setFrontPSILed(color:), setHoloProjectorLed(brightness:), setBackPSILed(color:), FrontPSIColor, BackPSIColor, red, blue, green, yellow, black, setLogicDisplayLeds(brightness:), wait(for:), play(sound:), for, ., R2D2Sound, happy, cautious, joyful, hello, excited, sad, scared, scan, talking)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, userCode_Lights(), assessmentController)
func startMessage() {

    flashLights()
}

func flashLights() {

}

//#-end-editable-code
//#-hidden-code
func userCode_Lights() {
//#-end-hidden-code
startMessage()
//#-hidden-code
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: userCode_Lights)

//#-end-hidden-code
