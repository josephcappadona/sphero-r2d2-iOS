//
//  ContentHelpers.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-28.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

fileprivate let toyBox = ToyBoxWrapper()
fileprivate var connectedToy: ToyWrapper?
fileprivate var currentHeading: Int = 0
fileprivate var waitListeners = [(Double)->()]()

internal let userCodeQueue = DispatchQueue(label: "com.sphero.code.queue", attributes: .concurrent)

internal func assertCommandIsSupported(commandName: String, supportingDescriptors: [String]) {
    
    if let connectedToy = connectedToy {
        if !supportingDescriptors.contains(connectedToy.descriptor) {
            
            let messageFormat = NSLocalizedString("contentHelpers.unsupportedToyCommand", value: "%@ does not support the %@ command.", comment: "The first %@ is replaced with the type of toy (SPRK+, BB-8, R2-D2). The 2nd %@ is replaced with a command (setMainLed etc.).")
            
            guard let toyName = [
                "D2-": "R2-D2",
                "BB-": "BB-8",
                "GB-": "BB-9E",
                "SK-": "SPRK+"
                ][connectedToy.descriptor] else {
                    fatalError("Unexpected toy descriptor: \(connectedToy.descriptor)")
            }
            
            let message = String(format: messageFormat, toyName, commandName)
            
            fatalError(message)
        }
    }
}

public func setupContent(assessment: AssessmentController, userCode: @escaping (() -> ())) {
    toyBox.addConnectionCallback(callback: { (toy: ToyWrapper) in
        connectedToy = toy
        currentHeading = 0
        assessment.assess(toy: toy, userCode: userCode, queue: userCodeQueue)
    })
    toyBox.readyToy()
}

/// Changes the color of the front LED light on R2-D2's dome. The `color` parameter can be `.blue` or `.red`. You can turn off the light by passing in `.black`. **Only available on R2-D2.**
///
/// - Parameter color: The desired color.
public func setFrontPSILed(color: FrontPSIColor) {
    assertCommandIsSupported(commandName: "setFrontPSILed(color:)", supportingDescriptors: [R2D2Toy.descriptor])
    connectedToy?.setFrontPSILed(color: color)
}

/// Changes the color of the back LED light on R2-D2's dome. The `color` parameter can be `.green` or `.yellow`. You can turn off the light by passing in `.black`. **Only available on R2-D2**
///
/// - Parameter color: The desired color.
public func setBackPSILed(color: BackPSIColor) {
    assertCommandIsSupported(commandName: "setBackPSILed(color:)", supportingDescriptors: [R2D2Toy.descriptor])
    connectedToy?.setBackPSILed(color: color)
}

/// Sets the brightness of the holoprojector LED, which is white color only. **Only available on R2-D2**
///
/// - Parameter brightness: The brightness of the LED from 0 to 255.
public func setHoloProjectorLed(brightness: Int) {
    assertCommandIsSupported(commandName: "setHoloProjectorLed(brightness:)", supportingDescriptors: [R2D2Toy.descriptor])
    connectedToy?.setHoloProjectorLed(brightness: Double(brightness))
}

/// Sets the brightness of the holoprojector LED, which is white color only. **Only available on R2-D2**
///
/// - Parameter brightness: The brightness of the LED from 0 to 255.
public func setLogicDisplayLeds(brightness: Int) {
    assertCommandIsSupported(commandName: "setLogicDisplayLeds(brightness:)", supportingDescriptors: [R2D2Toy.descriptor])
    connectedToy?.setLogicDisplayLeds(brightness: Double(brightness))
}

/// Sets the angle of R2-D2's dome. **Only available on R2-D2**
///
/// - Parameter angle: The angle of R2D2's dome from -100 to 100.
public func setDomePosition(angle: Int) {
    assertCommandIsSupported(commandName: "setDomePosition(angle:)", supportingDescriptors: [R2D2Toy.descriptor])
    connectedToy?.setDomePosition(angle: Double(angle))
}



public typealias R2D2Stance = StanceCommand.StanceId
/// Sets R2-D2's stance. Change between `.bipod`, `.tripod` or `.waddle`. Pass in `.stop` to stop waddling. **Only available on R2-D2**
///
/// - Parameter stance: The desired stance for R2D2. Use .stop to stop a waddle
public func setStance(_ stance: R2D2Stance) {
    setStanceImpl(stance)
}

public var setStanceImpl: ((_ stance: R2D2Stance)->()) = { stance in
    assertCommandIsSupported(commandName: "setStance(_:)", supportingDescriptors: [R2D2Toy.descriptor])
    connectedToy?.setStance(stance)
}

public typealias PlaybackMode = PlaySoundCommand.AudioPlaybackMode
/// Play a sound on R2-D2. **Only available on R2-D2**
///
/// - Parameter sound: The desired sound to play on R2D2.
public func play(sound: R2D2Sound, playbackMode: PlaybackMode = .playOnlyIfNotPlaying) {
    assertCommandIsSupported(commandName: "play(sound:playbackMode)", supportingDescriptors: [R2D2Toy.descriptor])
    
    connectedToy?.playSound(sound, playbackMode: playbackMode)
}

/// Play a animation on R2D2.
///
/// - Parameter animation: The desired animation to play on R2D2.
public func playAnimation(_ bundle: AnimationBundle) {
    connectedToy?.playAnimation(bundle)
}

/// Sets the power of the motors directly.
///
/// - Parameter leftMotorPower: The power for the left motor from 0 to 255
/// - Parameter leftMotorMode: The desired mode for the left motor
/// - Parameter rightMotorPower: The power for the right motor from 0 to 255
/// - Parameter rightMotorMode: The desired mode for the right motor
public func setRawMotor(leftMotorPower: Int, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Int, rightMotorMode: RawMotor.RawMotorMode) {
    connectedToy?.setRawMotor(leftMotorPower: Double(leftMotorPower),
                              leftMotorMode: leftMotorMode,
                              rightMotorPower: Double(rightMotorPower),
                              rightMotorMode: rightMotorMode)
}

/// Rolls your robot at a given heading and speed.
///
/// - Parameters:
///   - heading: The target heading from 0° to 360°.
///   - speed: The target speed from 0 to 255.
public func roll(heading: Int, speed: Int) {
    currentHeading = heading
    connectedToy?.roll(heading: Double(heading), speed: Double(speed))
}

/// Sets the target speed to 0, stopping your robot.
public func stopRoll() {
    connectedToy?.stopRoll(heading: Double(currentHeading))
}

/// Enters "aiming" mode allowing you to set the forward heading. After your robot has been aimed, call `stopAiming()`.
public func startAiming() {
    connectedToy?.startAiming()
}

/// Exits "aiming" mode and applies the new aim angle.
public func stopAiming() {
    connectedToy?.stopAiming()
    // stopAiming() causes the toy's heading to reset.
    currentHeading = 0
}

/// Waits for a number of seconds before running the next sequence of code.
///
/// - Parameter seconds: the number of seconds to wait
public func wait(for seconds: Double) {
    for listener in waitListeners {
        listener(seconds)
    }
    usleep(UInt32(seconds * 1e6))
}

internal func addWaitListener(_ listener: @escaping (Double)->()) {
    waitListeners.append(listener)
}

/// Enables streaming sensors.
/// You can select which sensors (locator, accelerometer, gyroscope, orientation) to enable with a `sensorMask`. Use `addSensorListener` to listen for sensor data.
///
/// - Parameter sensorMask: A list of sensors to enable.
public func enableSensors(sensorMask: SensorMask, interval: Int = 250) {
    connectedToy?.enableSensors(sensorMask: sensorMask, interval: interval)
}

/// Disables streaming sensors.
public func disableSensors() {
    connectedToy?.enableSensors(sensorMask: [])
}

/// Turns collision detection on or off.
/// Use the `.enabled` (on) and `.disabled` (off) configurations.
///
/// - Parameter configuration: The collison detection parameters.
public func setCollisionDetection(configuration: CollisionConfiguration) {
    connectedToy?.setCollisionDetection(configuration: configuration)
}

/// Registers a function that is called when your robot collides with something.
/// Details about the collision are provided in `collisionData`.
///
/// - Parameter listener: The function to call when a collision occures.
public func addCollisionListener(_ listener: @escaping CollisionListener) {
    assertCommandIsSupported(commandName: "addCollisionListener(_:)", supportingDescriptors: [SPRKToy.descriptor, BB8Toy.descriptor, BB9EToy.descriptor, R2D2Toy.descriptor])
    
    connectedToy?.addCollisionListener { (collisionData: CollisionData) in
        userCodeQueue.async {
            listener(collisionData)
        }
    }
}

/// Registers a function that is called when your robot reports sensor data.
/// Sensor values are provided in `sensorData`.
///
/// - Parameter listener: The function to call when sensor data is received.
public func addSensorListener(_ listener: @escaping SensorListener) {
    assertCommandIsSupported(commandName: "addSensorListener(_:)", supportingDescriptors: [SPRKToy.descriptor, BB8Toy.descriptor, BB9EToy.descriptor, R2D2Toy.descriptor])
    
    connectedToy?.addSensorListener { (sensorData: SensorControlData) in
        userCodeQueue.async {
            listener(sensorData)
        }
    }
}

/// Registers a function that is called when your robot reports it is in free fall.
///
/// - Parameter listener: The function to call when free fall is reported.
public func addFreefallListener(_ listener: @escaping FreefallListener) {
    assertCommandIsSupported(commandName: "addFreefallListener(_:)", supportingDescriptors: [SPRKToy.descriptor, BB8Toy.descriptor, BB9EToy.descriptor, R2D2Toy.descriptor])
    
    connectedToy?.addFreefallListener {
        userCodeQueue.async {
            listener()
        }
    }
}

/// Registers a function that is called when your robot reports that is has landed after free fall.
///
/// - Parameter listener: The function to call when a landing is reported.
public func addLandListener(_ listener: @escaping LandListener) {
    assertCommandIsSupported(commandName: "addLandListener(_:)", supportingDescriptors: [SPRKToy.descriptor, BB8Toy.descriptor, BB9EToy.descriptor, R2D2Toy.descriptor])
    
    connectedToy?.addLandListener {
        userCodeQueue.async {
            listener()
        }
    }
}

/// Changes the color of the main LED lights. Pass a `UIColor` object as the argument. You can turn off the lights by passing in `.black`. **Not available on R2-D2**
///
/// - Parameter color: The desired color.
public func setMainLed(color: UIColor) {
    assertCommandIsSupported(commandName: "setMainLed(color:)", supportingDescriptors: [SPRKToy.descriptor, BB8Toy.descriptor, BB9EToy.descriptor])
    
    connectedToy?.setMainLed(color: color)
}

/// Sets the brightness of the back aiming LED, which is blue color only. **Not available on R2-D2**
///
/// - Parameter brightness: The brightness of the LED from 0 to 255..
public func setBackLed(brightness: Double) {
    assertCommandIsSupported(commandName: "setBackLed(brightness:)", supportingDescriptors: [SPRKToy.descriptor, BB8Toy.descriptor, BB9EToy.descriptor])
    
    connectedToy?.setBackLed(brightness: brightness)
}

/// Sets the brightness of the head LED. **Only available on BB-9E**
///
/// - Parameter brightness: The brightness of the LED from 0 to 255..
public func setHeadLed(brightness: Double) {
    assertCommandIsSupported(commandName: "setHeadLed(brightness:)", supportingDescriptors: [BB9EToy.descriptor])
    
    connectedToy?.setHeadLed(brightness: brightness)
}

/// Registers a function that is called when the on-screen joystick is moved.
///
/// - Parameter listener: The function to call when the joystick is moved.
public typealias JoystickListener = (_ x: Double, _ y: Double) -> ()
public func addJoystickListener(_ listener: @escaping JoystickListener) {
    connectedToy?.addPlaygroundMessageListener({ (message: PlaygroundValue) in
        guard let dict = message.dictValue(),
            let type = dict[MessageKeys.type]?.typeIdValue(),
            type == .joystick,
            let x = dict[MessageKeys.x]?.doubleValue(),
            let y = dict[MessageKeys.y]?.doubleValue()
            else { return }
        
        listener(x, y)
    })
}

/// Registers a function that is called when the on-screen aim control is moved.
///
/// - Parameter listener: The function to call when the aim control is moved.
public typealias AimHeadingListener = (_ heading: Int) -> ()
public func addAimHeadingListener(_ listener: @escaping AimHeadingListener) {
    connectedToy?.addPlaygroundMessageListener({ (message: PlaygroundValue) in
        guard let dict = message.dictValue(),
            let type = dict[MessageKeys.type]?.typeIdValue(),
            type == .aimControlHeading,
            let heading = dict[MessageKeys.heading]?.intValue()
            else { return }
        
        listener(heading)
    })
}

public typealias AimStateListener = () -> ()

/// Registers a function that is called when interaction with the on-screen aim control begins.
///
/// - Parameter listener: The function to call when the aim control is first activated.
public func addAimStartListener(_ listener: @escaping AimStateListener) {
    connectedToy?.addPlaygroundMessageListener({ (message: PlaygroundValue) in
        guard let dict = message.dictValue(),
            let type = dict[MessageKeys.type]?.typeIdValue(),
            type == .aimControlStart
            else { return }
        
        listener()
    })
}

/// Registers a function that is called when interaction with the on-screen aim control ends.
///
/// - Parameter listener: The function to call when the aim control is released.
public func addAimStopListener(_ listener: @escaping AimStateListener) {
    connectedToy?.addPlaygroundMessageListener({ (message: PlaygroundValue) in
        guard let dict = message.dictValue(),
            let type = dict[MessageKeys.type]?.typeIdValue(),
            type == .aimControlStop
            else { return }
        
        listener()
    })
}

/// Changes the robot's orientation.
///
/// - Parameters:
///   - heading: The target heading from 0° to 360°.
public func rotateAim(heading: Int) {
    connectedToy?.rotateAim(heading: Double(heading))
}

/// Reset the locator's current x and y position to zero.
public func resetLocator() {
    connectedToy?.resetLocator()
}

public typealias StabilizationState = SetStabilization.State
// Turns the stabilization system on or off, which is used for aiming. Stabilization is on by default to keep your robot upright inside it's shell. **Not available on R2-D2**
// - Parameter state: `.on` to turn stabilization on, `.off` to turn it off.
public func setStabilization(state: StabilizationState) {
    assertCommandIsSupported(commandName: "setHeadLed(brightness:)", supportingDescriptors: [SPRKToy.descriptor, BB8Toy.descriptor, BB9EToy.descriptor])
    
    connectedToy?.setStabilization(state: state)
}
