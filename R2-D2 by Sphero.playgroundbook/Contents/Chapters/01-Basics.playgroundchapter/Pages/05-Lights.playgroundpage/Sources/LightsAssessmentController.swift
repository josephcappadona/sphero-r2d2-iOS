//
//  LightsAssessmentController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import PlaygroundSupport
import Foundation

public class LightsAssessmentController: AssessmentController {
    
    class LightsPair {
        var holoprojectorBrightness = -1.0 {
            didSet {
                if lightStatus == .unset {
                    if holoprojectorBrightness == 0 {
                        lightStatus = .off
                    } else if holoprojectorBrightness > 0 {
                        lightStatus = .on
                    }
                }
                
                if holoprojectorBrightness >= 0 && logicDisplayBrightness >= 0 {
                    didSetPair = true
                }
                
                checkLightStatus()
            }
        }
        
        var logicDisplayBrightness = -1.0 {
            didSet {
                if lightStatus == .unset {
                    if logicDisplayBrightness == 0 {
                        lightStatus = .off
                    } else if logicDisplayBrightness > 0 {
                        lightStatus = .on
                    }
                }
                
                if holoprojectorBrightness >= 0 && logicDisplayBrightness >= 0 {
                    didSetPair = true
                }
                
                checkLightStatus()
            }
        }
        
        var didSetPair = false
        var lightStatus: LightStatus = .unset
        var failMessage: String?
        
        func reset() {
            didSetPair = false
            holoprojectorBrightness = -1.0
            logicDisplayBrightness = -1.0
        }
        
        private func checkLightStatus() {
            guard didSetPair else { return }
            
            if lightStatus == .on && (holoprojectorBrightness == 0 || logicDisplayBrightness == 0) {
                failMessage = NSLocalizedString("lightAssessmentFail.wrongLightCombination", value: "You need to turn both the holoprojector and the logic displays on at the same time.", comment: "light assessment fail, wrong holo light combination")
            } else if lightStatus == .off && (holoprojectorBrightness > 0 || logicDisplayBrightness > 0) {
                failMessage = NSLocalizedString("lightAssessmentFail.wrongLightCombination2", value: "You need to turn both the holoprojector and the logic displays off at the same time.", comment: "light assessment fail, wrong holo light combination")
            } else {
                failMessage = nil
            }
        }
        
        enum LightStatus {
            case unset
            case on
            case off
        }
    }
    
    private var lightPair = LightsPair()
    private var didSetFrontPSI = false
    private var didSetBackPSI = false
    private var didPlaySound = false
    private var didSetHoloLed = false
    private var didSetLogicLed = false
    private var didWaitAfterUpdatingLeds = false
    private var lastLightStatus = LightsPair.LightStatus.unset
    private var flashLightsCount = 0
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus?  {
        switch event.data {
        case .frontPSILed(color: _):
            didSetFrontPSI = true
            
        case .backPSILed(color: _):
            didSetBackPSI = true
            
        case let .holoProjectorLed(brightness: brightness):
            
            if lightPair.holoprojectorBrightness == brightness {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.wrongHoloBrightness", value: "You need to flash R2-D2's holoprojector. Set it from `0` to `255` to turn it off and on.", comment: "light assessment fail, wrong holo brightness")], solution: nil)
            }
            
            if !didWaitAfterUpdatingLeds && lightPair.holoprojectorBrightness >= 0 {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.noLedWwait", value: "You need to wait between updating the LEDs to get a flashing effect. Try using the `wait` function after updating both the holoprojector and logic displays.", comment: "light assessment fail, didn't wait.")], solution: nil)
            }
            
            lightPair.holoprojectorBrightness = brightness
            didSetHoloLed = true
            didWaitAfterUpdatingLeds = false
            
        case let .logicDisplayLed(brightness: brightness):
            
            if lightPair.logicDisplayBrightness == brightness {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.wrongLogicBrightness", value: "You need to flash R2-D2's logic displays. Set them from `0` to `255` to turn them off and on.", comment: "light assessment fail, wrong logic display brightness")], solution: nil)
            }
            
            if !didWaitAfterUpdatingLeds && lightPair.logicDisplayBrightness >= 0 {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.noLedWwait", value: "You need to wait between updating the LEDs. Try using the `wait` function after updating both the holoprojector and logic displays.", comment: "light assessment fail, didn't wait.")], solution: nil)
            }
            
            lightPair.logicDisplayBrightness = brightness
            didSetLogicLed = true
            didWaitAfterUpdatingLeds = false
            
        case let .wait(seconds: seconds):
            if didPlaySound {
                if !lightPair.didSetPair {
                    return .fail(hints: [NSLocalizedString("lightAssessmentFail.wrongWaitTimes", value: "You need to toggle both the holoprojector and logic display LEDs before waiting.", comment: "light assessment fail, wrong time to wait.")], solution: nil)
                }
                
                if let failMessage = lightPair.failMessage {
                    return .fail(hints: [failMessage], solution: nil)
                }
                
                if lightPair.didSetPair && lightPair.failMessage == nil {
                    didWaitAfterUpdatingLeds = true
                    lightPair.reset()
                }
                
                if lastLightStatus == .unset {
                    lastLightStatus = lightPair.lightStatus
                } else if lastLightStatus != lightPair.lightStatus {
                    flashLightsCount = flashLightsCount + 1
                }
                
                lightPair.lightStatus = .unset
            }
            
        case let .playSound(sound: sound):
            guard sound == .talking else {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.wrongSound", value: "You correctly played a sound, but it wasn't R2-D2 talking. R2-D2 should be talking when it is sharing its message!", comment: "light assessment fail, wrong sound played")], solution: nil)
            }
            
            didPlaySound = true
            
        case .userCodeFinished:
            if !didSetFrontPSI {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.noFrontPSIColor", value: "You never turned on R2-D2's front LED. Use the `setFrontPSILed` function to turn it on!", comment: "light assessment fail, front light not turned on")], solution: nil)
            }
            
            if !didSetBackPSI {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.noRearPSIColor", value: "You never turned on R2-D2's back LED. Use the `setBackPSILed` function to turn it on!", comment: "light assessment fail, rear light not turned on")], solution: nil)
            }
            
            if !didSetHoloLed {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.noRearHoloLed", value: "You never turned on R2-D2's holoprojector LED. Use the `setHoloProjectorLed` function in the `flashLights` function to turn it on!", comment: "light assessment fail, holoprojector light not turned on")], solution: nil)
            }
            
            if !didSetLogicLed {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.noRearPSIColor", value: "You never turned on R2-D2's logic display LEDs. Use the `setLogicDisplayLeds` in the `flashLights` function to turn them on!", comment: "light assessment fail, logic displays not turned on")], solution: nil)
            }
            
            if flashLightsCount == 0 {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.noLightsFlash", value: "You never called the `flashLights` function.", comment: "light assessment fail, no flash lights called")], solution: nil)
            }
            
            if flashLightsCount < 4 {
                return .fail(hints: [NSLocalizedString("lightAssessmentFail.notEnoughLightsFlash", value: "You need to call `flashLights` at least four times. Try putting it in a `for` loop.", comment: "light assessment fail, not enough flash lights called")], solution: nil)
            }
            
            let message = NSLocalizedString("lightsAssessment.pass", value: "### Congratulations! \nR2-D2 successfully shared its message!\nOn to the [next chapter](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nR2-D2 successfully shared its message!\nOn to the [next page]'")
            
            return .pass(message: message)
            
        default:
            break
        }
        
        return nil
    }
    
}
