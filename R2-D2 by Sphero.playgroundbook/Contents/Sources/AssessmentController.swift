//
//  AssessmentController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit
import PlaygroundSupport

public enum AssessmentEventData {
    case roll(speed: Double, heading: Double)
    case stopRoll(heading: Double)
    
    case mainLed(color: UIColor)
    case frontPSILed(color: UIColor)
    case backPSILed(color: UIColor)
    case holoProjectorLed(brightness: Double)
    case logicDisplayLed(brightness: Double)
    
    case headPosition(angle: Double)
    case stance(StanceCommand.StanceId)
    
    case playSound(sound: R2D2Sound)
    case enableSensors
    case collision(data: CollisionData)
    
    case userCodeFinished
    case wait(seconds: Double)
}

public struct AssessmentEvent {
    public var data: AssessmentEventData
    public var timestamp: TimeInterval
    
    public init(data: AssessmentEventData) {
        self.data = data
        self.timestamp = Date().timeIntervalSince1970
    }
}

open class AssessmentController: ToyCommandListener {

    public var didMakeAssessment = false
    
    public init() {}
    
    open func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        return nil // fatalError("This method should be overridden")
    }
    
    open func assess(toy: ToyWrapper, userCode: @escaping () -> (), queue: DispatchQueue) {
        toy.addCommandListener(self)
        toy.addCollisionListener(self.onCollision)
        toy.addPlaygroundMessageListener(self.onMessage)
        
        addWaitListener(self.onWait)
        
        queue.async {
            userCode()
            self.userCodeFinished()
        }
    }
    
    public func setMainLed(color: UIColor) {
        updateAssessmentStatus(data: .mainLed(color: color))
    }
    
    public func setHeadLed(brightness: Double) { }
    
    public func setFrontPSILed(color: FrontPSIColor) {
        updateAssessmentStatus(data: .frontPSILed(color: color.color()))
    }
    
    public func setBackPSILed(color: BackPSIColor) {
        updateAssessmentStatus(data: .backPSILed(color: color.color()))
    }
    
    public func setLogicDisplayLeds(brightness: Double) {
        updateAssessmentStatus(data: .logicDisplayLed(brightness: brightness))
    }
    
    public func setHoloProjectorLed(brightness: Double) {
        updateAssessmentStatus(data: .holoProjectorLed(brightness: brightness))
    }
    
    public func setRawMotor(leftMotorPower: Double, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Double, rightMotorMode: RawMotor.RawMotorMode) { }
    
    public func setDomePosition(angle: Double) {
        updateAssessmentStatus(data: .headPosition(angle: angle))
    }
    
    public func setStance(_ stance: StanceCommand.StanceId) {
        updateAssessmentStatus(data: .stance(stance))
    }
    
    public func startAiming() { }
    public func stopAiming() { }
    public func playAnimation(_ bundle: AnimationBundle) { }
    public func resetLocator() { }
    public func setBackLed(brightness: Double) { }
    public func setStabilization(state: StabilizationState) { }
    
    public func playSound(sound: R2D2Sound, playbackMode: PlaySoundCommand.AudioPlaybackMode) {
        updateAssessmentStatus(data: .playSound(sound: sound))
    }
    
    public func roll(heading: Double, speed: Double) {
        updateAssessmentStatus(data: .roll(speed: speed, heading: heading))
    }
    
    public func rotateAim(heading: Double) { }
    
    public func stopRoll(heading: Double) {
        updateAssessmentStatus(data: .stopRoll(heading: heading))
    }
    
    public func enableSensors(sensorMask: SensorMask, interval: Int) {
        updateAssessmentStatus(data: .enableSensors)
    }
    
    private func onCollision(_ collisionData: CollisionData) {
        updateAssessmentStatus(data: .collision(data: collisionData))
    }
    
    public func userCodeFinished() {
        updateAssessmentStatus(data: .userCodeFinished)
    }
    
    public func setCollisionDetection(configuration: CollisionConfiguration) { }
    
    private func onWait(seconds: Double) {
        updateAssessmentStatus(data: .wait(seconds: seconds))
    }
    
    private func updateAssessmentStatus(data: AssessmentEventData) {
        guard !didMakeAssessment else { return }
        
        let event = AssessmentEvent(data: data)
        
        if let status = assess(event: event) {
            makeAssessment(status: status)
        }
    }
    
    open func makeAssessment(status: PlaygroundPage.AssessmentStatus, finishingExecution shouldFinishExecution: Bool = true) {
        guard !didMakeAssessment else { return }
        didMakeAssessment = true

        var playAnimationMessageDict = [String:PlaygroundValue]()
        playAnimationMessageDict[MessageKeys.type] = MessageTypeId.playAnimation.playgroundValue()

        switch status {
        case .fail(hints: _, solution: _):
            playAnimationMessageDict[MessageKeys.animationBundleId] = .integer(R2D2Animations.sad.animationId)
            
        case .pass(message: _):
            playAnimationMessageDict[MessageKeys.animationBundleId] = .integer(R2D2Animations.happy.animationId)
            
        }
        
        PlaygroundHelpers.sendMessageToLiveView(.dictionary(playAnimationMessageDict))
        
        DispatchQueue.main.async {
            PlaygroundPage.current.assessmentStatus = status
            if shouldFinishExecution {
                PlaygroundPage.current.finishExecution()
            }
        }
    }
    
    open func onMessage(_ message: PlaygroundValue) {
        if let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue(),
            typeId == MessageTypeId.didDisconnect.rawValue {
            
            let hint = NSLocalizedString("asessment.unexpectedDisconnect", value: "R2-D2 disconnected! Connect R2-D2 and run your code to try again.", comment: "Assessment hint when the toy disconnects unexpectedly while code is running.")
            makeAssessment(status: .fail(hints: [hint], solution: nil))
        }
    }
}
