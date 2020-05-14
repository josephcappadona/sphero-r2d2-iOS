//
//  ToyMessage.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-16.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

extension PlaygroundValue {
    
    public func doubleValue() -> Double? {
        
        switch self {
        case .floatingPoint(let value):
            return value
        default:
            return nil
        }
    }
    
    public func stringValue() -> String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
    
    public func dictValue() -> [String:PlaygroundValue]? {
        switch self {
        case .dictionary(let dict):
            return dict
        default:
            return nil
        }
    }
    
    public func intValue() -> Int? {
        switch self {
        case .integer(let value):
            return value
        default:
            return nil
        }
    }
    
    public func boolValue() -> Bool? {
        switch self {
        case .boolean(let value):
            return value
        default:
            return nil
        }
    }
    
    public func arrayValue() -> [PlaygroundValue]? {
        switch self {
        case .array(let value):
            return value
        default:
            return nil
        }
    }
    
    public func typeIdValue() -> MessageTypeId? {
        guard let typeRaw = self.intValue(),
            let type = MessageTypeId(rawValue: typeRaw)
            else { return nil }
        
        return type
    }
    
    public func colorValue() -> UIColor? {
        guard let dict = self.dictValue(),
            let red = dict[MessageKeys.red]?.doubleValue(),
            let green = dict[MessageKeys.green]?.doubleValue(),
            let blue = dict[MessageKeys.blue]?.doubleValue(),
            let alpha = dict[MessageKeys.alpha]?.doubleValue() else { return nil }
        
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    public init(color: UIColor) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self = .dictionary([
            MessageKeys.red: PlaygroundValue.floatingPoint(Double(red)),
            MessageKeys.green: PlaygroundValue.floatingPoint(Double(green)),
            MessageKeys.blue: PlaygroundValue.floatingPoint(Double(blue)),
            MessageKeys.alpha: PlaygroundValue.floatingPoint(Double(alpha)),
            ])
    }
}

public enum MessageTypeId: Int {
    case connect = 0
    case didConnect = 1
    case didDisconnect = -1
    
    case roll = 2
    case rotateAim = 161
    case stopRoll = 3
    
    case setMainLed = 4
    case setFrontPSILed = 5
    case setBackPSILed = 6
    case setHoloProjectorLed = 7
    case setLogicDisplayLed = 8
    case setHeadLed = 160
    case setBackLed = 162
    
    case setDomePosition = 9
    case setStance = 10
    case setStabilization = 163
    
    case playSound = 170
    case playAnimation = 171
    
    case setCollisionDetection = 12
    case collisionDetected = 13
    
    case rawMotor = 14
    
    case startAiming = 15
    case stopAiming = 16
    
    case sensorData = 17
    case enableSensors = 18
    case resetLocator = 19
    
    case toyReady = 20
    
    case playAssessmentSound = 41
    
    case freefallDetected = 50
    case landDetected = 51
    
    case artooMovementRequest = 100
    case artooMovementResponse = 101
    case artooReachedEnd = 102
    
    case hackingStart = 110
    case hackingContinue = 111
    case hackingCancelled = 112
    case hackingCodeEntered = 113
    
    case scanStart = 120
    case scanStop = 121
    
    case stormtrooperDistance = 130
    
    case showEscapePod = 140
    
    case joystick = 150
    case aimControlStart = 151
    case aimControlStop = 152
    case aimControlHeading = 153

    public func playgroundValue() -> PlaygroundValue {
        return PlaygroundValue.integer(self.rawValue)
    }
    
    public init?(value: PlaygroundValue) {
        guard let rawValue = value.intValue() else { return nil }
        guard let typeId = MessageTypeId(rawValue: rawValue) else { return nil }
        
        self = typeId
    }
}

public enum MessageKeys {
    public static let type = "type"
    public static let descriptor = "descriptor"
    
    public static let speed = "speed"
    public static let heading = "heading"
    
    public static let leftMotorPower = "leftMotorPower"
    public static let rightMotorPower = "rightMotorPower"
    
    public static let leftMotorMode = "leftMotorMode"
    public static let rightMotorMode = "rightMotorMode"
    
    public static let mainLedColor = "mainLedColor"
    
    public static let frontPSILedColor = "frontPSILedColor"
    public static let backPSILedColor = "backPSILedColor"
    
    public static let domePosition = "domePosition"
    public static let stance = "stance"
    
    public static let soundId = "soundId"
    public static let playbackMode = "playbackMode"
    
    public static let animationBundleId = "animationBundleId"
    
    public static let red = "red"
    public static let green = "green"
    public static let blue = "blue"
    public static let alpha = "alpha"
    
    public static let brightness = "brightness"
    
    public static let state = "state"
    
    public static let impactAcceleration = "impactAcceleration"
    public static let impactAxis = "impactAxis"
    public static let impactPower = "impactPower"
    public static let impactSpeed = "impactSpeed"
    public static let timestamp = "timestamp"
    
    public static let detectionMethod = "detectionMethod"
    public static let threshold = "threshold"
    public static let speedThreshold = "speedThreshold"
    public static let postTimeDeadZone = "postTimeDeadZone"
    
    public static let newX = "newX"
    public static let newY = "newY"
    public static let newYaw = "newYaw"
    
    public static let sensorMask = "sensorMask"
    public static let sensorInterval = "sensorInterval"
    public static let locator = "locator"
    public static let orientation = "orientation"
    public static let gyro = "gyro"
    public static let accelerometer = "accelerometer"
    public static let position = "position"
    public static let velocity = "velocity"
    public static let filtered = "filtered"
    public static let raw = "raw"
    
    public static let assessmentSoundKey = "assessmentSoundKey"
    
    public static let x = "x"
    public static let y = "y"
    public static let z = "z"
    
    public static let angle = "angle"
    public static let distance = "distance"
    public static let command = "command"
    
    public static let code = "code"
    public static let identifier = "identifier"
}

public class ToyMessageSender: ToyCommandListener {
    public init() {}
    
    private func send(_ value: PlaygroundValue) {
        PlaygroundHelpers.sendMessageToLiveView(value)
    }
    
    public func roll(heading: Double, speed: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.roll.playgroundValue(),
            MessageKeys.heading: PlaygroundValue.floatingPoint(heading),
            MessageKeys.speed: PlaygroundValue.floatingPoint(speed)
            ]))
    }
    
    public func rotateAim(heading: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.rotateAim.playgroundValue(),
            MessageKeys.heading: PlaygroundValue.floatingPoint(heading)
            ]))
    }

    public func stopRoll(heading: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.stopRoll.playgroundValue(),
            MessageKeys.heading: PlaygroundValue.floatingPoint(heading)
            ]))
    }
    
    public func startAiming() {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.startAiming.playgroundValue()
            ]))
    }
    
    public func stopAiming() {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.stopAiming.playgroundValue()
            ]))
    }
    
    public func setMainLed(color: UIColor) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setMainLed.playgroundValue(),
            MessageKeys.mainLedColor: PlaygroundValue(color: color)
        ]))
    }
    
    public func setBackLed(brightness: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setBackLed.playgroundValue(),
            MessageKeys.brightness: .floatingPoint(brightness)
        ]))
    }
    
    public func setHeadLed(brightness: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setHeadLed.playgroundValue(),
            MessageKeys.brightness: PlaygroundValue.floatingPoint(brightness)
            ]))
    }

    
    public func setFrontPSILed(color: FrontPSIColor) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setFrontPSILed.playgroundValue(),
            MessageKeys.frontPSILedColor: PlaygroundValue(color: color.color())
            ]))
    }
    
    public func setBackPSILed(color: BackPSIColor) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setBackPSILed.playgroundValue(),
            MessageKeys.backPSILedColor: PlaygroundValue(color: color.color())
            ]))
    }
    
    public func setHoloProjectorLed(brightness: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setHoloProjectorLed.playgroundValue(),
            MessageKeys.brightness: PlaygroundValue.floatingPoint(brightness)
            ]))
    }
    
    public func setLogicDisplayLeds(brightness: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setLogicDisplayLed.playgroundValue(),
            MessageKeys.brightness: PlaygroundValue.floatingPoint(brightness)
            ]))
    }
    
    public func setDomePosition(angle: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setDomePosition.playgroundValue(),
            MessageKeys.domePosition: PlaygroundValue.floatingPoint(angle)
            ]))
    }
    
    public func setStance(_ stance: StanceCommand.StanceId) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setStance.playgroundValue(),
            MessageKeys.stance: PlaygroundValue.integer(Int(stance.rawValue))
            ]))
    }
    
    public func playSound(sound: R2D2Sound, playbackMode: PlaySoundCommand.AudioPlaybackMode) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.playSound.playgroundValue(),
            MessageKeys.soundId: PlaygroundValue.integer(Int(sound.rawValue)),
            MessageKeys.playbackMode: PlaygroundValue.integer(Int(playbackMode.rawValue))
            ]))
    }
    
    public func playAnimation(_ bundle: AnimationBundle) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.playAnimation.playgroundValue(),
            MessageKeys.animationBundleId: PlaygroundValue.integer(bundle.animationId)
            ]))
    }
    
    public func setCollisionDetection(configuration: CollisionConfiguration) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setCollisionDetection.playgroundValue(),
            MessageKeys.detectionMethod: PlaygroundValue.integer(Int(configuration.detectionMethod.rawValue)),
            MessageKeys.threshold: PlaygroundValue.dictionary([
                MessageKeys.x: PlaygroundValue.integer(Int(configuration.xThreshold)),
                MessageKeys.y: PlaygroundValue.integer(Int(configuration.yThreshold))]),
            MessageKeys.speedThreshold: PlaygroundValue.dictionary([
                MessageKeys.x: PlaygroundValue.integer(Int(configuration.xSpeedThreshold)),
                MessageKeys.y: PlaygroundValue.integer(Int(configuration.ySpeedThreshold))]),
            MessageKeys.postTimeDeadZone: PlaygroundValue.floatingPoint(configuration.postTimeDeadZone)
            ]))
    }
    
    public func setRawMotor(leftMotorPower: Double, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Double, rightMotorMode: RawMotor.RawMotorMode) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.rawMotor.playgroundValue(),
            MessageKeys.leftMotorPower: PlaygroundValue.floatingPoint(leftMotorPower),
            MessageKeys.leftMotorMode: PlaygroundValue.integer(Int(leftMotorMode.rawValue)),
            MessageKeys.rightMotorPower: PlaygroundValue.floatingPoint(rightMotorPower),
            MessageKeys.rightMotorMode: PlaygroundValue.integer(Int(rightMotorMode.rawValue))
            
            ]))
    }
    
    public func enableSensors(sensorMask: SensorMask, interval: Int) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.enableSensors.playgroundValue(),
            MessageKeys.sensorMask: PlaygroundValue.array(sensorMask.map { PlaygroundValue.integer($0.rawValue) }),
            MessageKeys.sensorInterval: PlaygroundValue.integer(interval)
            ]))
    }
    
    public func resetLocator() {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.resetLocator.playgroundValue()
            ]))
    }
    
    public func setStabilization(state: StabilizationState) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setStabilization.playgroundValue(),
            MessageKeys.state: .integer(Int(state.rawValue))
        ]))
    }
}

