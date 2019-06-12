//
//  ToyWrapper.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-16.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit


public typealias CollisionListener = (_ collisionData: CollisionData) -> Void
public typealias SensorListener = (_ sensorData: SensorControlData) -> Void
public typealias FreefallListener = () -> ()
public typealias LandListener = () -> ()

public protocol ToyCommandListener {
    
    //LEDs
    func setMainLed(color: UIColor)
    func setHeadLed(brightness: Double)
    func setFrontPSILed(color: FrontPSIColor)
    func setBackPSILed(color: BackPSIColor)
    func setHoloProjectorLed(brightness: Double)
    func setLogicDisplayLeds(brightness: Double)
    func setBackLed(brightness: Double)
    func setBackLed(color: UIColor)
    func setFrontLed(color: UIColor)
    func drawMatrix(pixel: Pixel, color: UIColor)
    func drawMatrixLine(from startPixel: Pixel, to endPixel: Pixel, color: UIColor)
    func drawMatrix(fillFrom startPixel: Pixel, to endPixel: Pixel, color: UIColor)
    func setMatrix(color: UIColor)
    func clearMatrix()
    func setMatrix(rotation: MatrixRotation)
    func scrollMatrix(text: String, color: UIColor, speed: Int, loop: ScrollingTextLoopMode)
    
    //motors
    func roll(heading: Double, speed: Double)
    func rotateAim(heading: Double)
    func stopRoll(heading: Double)
    func setRawMotor(leftMotorPower: Double, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Double, rightMotorMode: RawMotor.RawMotorMode)
    
    func playSound(sound: R2D2Sound, playbackMode: PlaySoundCommand.AudioPlaybackMode)
    func playAnimation(_ bundle: AnimationBundle)
    func startAiming()
    func stopAiming()
    
    func setDomePosition(angle: Double)
    func setStance(_ stance: StanceCommand.StanceId)
    
    func setCollisionDetection(configuration: CollisionConfiguration)
    func enableSensors(sensorMask: SensorMask, interval: Int)
    func resetLocator()
    func setStabilization(state: StabilizationState)
}

// Default implementation of SPRKCommandListener with empty methods,
// so listeners can just override the methods they need.
open class ToyAdapter: ToyCommandListener {
    public init() {}
    
    public func setMainLed(color: UIColor) {}
    public func setHeadLed(brightness: Double) { }
    public func setFrontPSILed(color: FrontPSIColor) { }
    public func setBackPSILed(color: BackPSIColor) { }
    public func setHoloProjectorLed(brightness: Double) { }
    public func setLogicDisplayLeds(brightness: Double) { }
    public func setBackLed(brightness: Double) { }
    public func setBackLed(color: UIColor) { }
    public func setFrontLed(color: UIColor) { }
    public func drawMatrix(pixel: Pixel, color: UIColor) { }
    public func drawMatrixLine(from: Pixel, to: Pixel, color: UIColor) { }
    public func drawMatrix(fillFrom startPixel: Pixel, to endPixel: Pixel, color: UIColor) { }
    public func setMatrix(color: UIColor) { }
    public func clearMatrix() { }
    public func setMatrix(rotation: MatrixRotation) { }
    public func scrollMatrix(text: String, color: UIColor, speed: Int, loop: ScrollingTextLoopMode) { }
    
    public func roll(heading: Double, speed: Double) { }
    public func rotateAim(heading: Double) { }
    public func stopRoll(heading: Double) { }
    public func setRawMotor(leftMotorPower: Double, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Double, rightMotorMode: RawMotor.RawMotorMode) { }
    
    public func playSound(sound: R2D2Sound, playbackMode: PlaySoundCommand.AudioPlaybackMode) { }
    public func playAnimation(_ bundle: AnimationBundle) { }
    public func startAiming() { }
    public func stopAiming() { }
    
    public func setDomePosition(angle: Double) { }
    public func setStance(_ stance: StanceCommand.StanceId) { }
    
    public func setCollisionDetection(configuration: CollisionConfiguration) { }
    public func enableSensors(sensorMask: SensorMask, interval: Int) { }
    public func resetLocator() { }
    public func setStabilization(state: StabilizationState) { }
}

public class ToyWrapper {
    
    public let descriptor: String
    
    public init(descriptor: String) {
        self.descriptor = descriptor
    }
    
    private var commandListeners = [ToyCommandListener]()
    private var collisionListeners = [CollisionListener]()
    private var sensorListeners = [SensorListener]()
    private var freefallListeners = [FreefallListener]()
    private var landListeners = [LandListener]()
    
    public func addCommandListener(_ listener: ToyCommandListener) {
        commandListeners.append(listener)
    }
    
    public func addCollisionListener(_ listener: @escaping CollisionListener) {
        collisionListeners.append(listener)
    }
    
    public func addSensorListener(_ listener: @escaping SensorListener) {
        sensorListeners.append(listener)
    }
    
    public func addFreefallListener(_ listener: @escaping FreefallListener) {
        freefallListeners.append(listener)
    }
    
    public func addLandListener(_ listener: @escaping LandListener) {
        landListeners.append(listener)
    }
    
    public func setFrontPSILed(color: FrontPSIColor) {
        commandListeners.forEach { $0.setFrontPSILed(color: color) }
    }
    
    public func setBackPSILed(color: BackPSIColor) {
        commandListeners.forEach { $0.setBackPSILed(color: color) }
    }
    
    public func setBackLed(brightness: Double) {
        commandListeners.forEach { $0.setBackLed(brightness: brightness) }
    }
    
    public func setBackLed(color: UIColor) {
        commandListeners.forEach { $0.setBackLed(color: color) }
    }
    
    public func setFrontLed(color: UIColor) {
        commandListeners.forEach { $0.setFrontLed(color: color) }
    }
    
    public func drawMatrix(pixel: Pixel, color: UIColor) {
        commandListeners.forEach { $0.drawMatrix(pixel: pixel, color: color) }
    }
    
    public func drawMatrixLine(from startPixel: Pixel, to endPixel: Pixel, color: UIColor) {
        commandListeners.forEach { $0.drawMatrixLine(from: startPixel, to: endPixel, color: color) }
    }
    
    public func drawMatrix(fillFrom startPixel: Pixel, to endPixel: Pixel, color: UIColor) {
        commandListeners.forEach { $0.drawMatrix(fillFrom: startPixel, to: endPixel, color: color) }
    }
    public func setMatrix(color: UIColor) {
        commandListeners.forEach { $0.setMatrix(color: color) }
    }
    
    public func clearMatrix() {
        commandListeners.forEach { $0.clearMatrix() }
    }
    public func setMatrix(rotation: MatrixRotation) {
        commandListeners.forEach { $0.setMatrix(rotation: rotation) }
    }
    public func scrollMatrix(text: String, color: UIColor, speed: Int, loop: ScrollingTextLoopMode) {
        commandListeners.forEach { $0.scrollMatrix(text: text, color: color, speed: speed, loop: loop) }
    }
    
    public func setHoloProjectorLed(brightness: Double) {
        commandListeners.forEach { $0.setHoloProjectorLed(brightness: brightness) }
    }
    
    public func setLogicDisplayLeds(brightness: Double) {
        commandListeners.forEach { $0.setLogicDisplayLeds(brightness: brightness) }
    }
    
    public func setDomePosition(angle: Double) {
        commandListeners.forEach { $0.setDomePosition(angle: angle) }
    }
    
    public func setStance(_ stance: StanceCommand.StanceId) {
        commandListeners.forEach { $0.setStance(stance) }
    }
    
    public func enableSensors(sensorMask: SensorMask, interval: Int = 250) {
        commandListeners.forEach { $0.enableSensors(sensorMask: sensorMask, interval: interval) }
    }
    
    public func setCollisionDetection(configuration: CollisionConfiguration) {
        commandListeners.forEach { $0.setCollisionDetection(configuration: configuration) }
    }
    
    public func setRawMotor(leftMotorPower: Double, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Double, rightMotorMode: RawMotor.RawMotorMode) {
        commandListeners.forEach { $0.setRawMotor(leftMotorPower: leftMotorPower,
                                                  leftMotorMode: leftMotorMode,
                                                  rightMotorPower: rightMotorPower,
                                                  rightMotorMode: rightMotorMode) }
    }
    
    public func roll(heading: Double, speed: Double) {
        commandListeners.forEach { $0.roll(heading: heading, speed: speed) }
    }
    
    public func rotateAim(heading: Double) {
        commandListeners.forEach { $0.rotateAim(heading: heading) }
    }
    
    public func stopRoll(heading: Double) {
        commandListeners.forEach { $0.stopRoll(heading: heading) }
    }
    
    public func playSound(_ sound: R2D2Sound, playbackMode: PlaySoundCommand.AudioPlaybackMode) {
        commandListeners.forEach { $0.playSound(sound: sound, playbackMode: playbackMode) }
    }
    
    public func playAnimation(_ bundle: AnimationBundle) {
        commandListeners.forEach { $0.playAnimation(bundle) }
    }
    
    public func startAiming() {
        commandListeners.forEach { $0.startAiming() }
    }
    
    public func stopAiming() {
        commandListeners.forEach { $0.stopAiming() }
    }
    
    public func setMainLed(color: UIColor) {
        commandListeners.forEach { $0.setMainLed(color: color) }
    }
    
    public func setHeadLed(brightness: Double ) {
        commandListeners.forEach { $0.setHeadLed(brightness: brightness) }
    }
    
    public func resetLocator() {
        commandListeners.forEach { $0.resetLocator() }
    }
    
    public func setStabilization(state: StabilizationState) {
        commandListeners.forEach { $0.setStabilization(state: state) }
    }
    /*
    public func receive(_ message: PlaygroundValue) {
        guard let dict = message.dictValue() else { return }
        
        guard let typeIdValue = dict[MessageKeys.type] else { return }
        guard let typeId = MessageTypeId(value: typeIdValue) else { return }
        
        switch typeId {
        case .collisionDetected:
            guard let impactAccelerationDict = dict[MessageKeys.impactAcceleration]?.dictValue() else { return }
            guard let impactAccelerationX = impactAccelerationDict[MessageKeys.x]?.doubleValue() else { return }
            guard let impactAccelerationY = impactAccelerationDict[MessageKeys.y]?.doubleValue() else { return }
            guard let impactAccelerationZ = impactAccelerationDict[MessageKeys.z]?.doubleValue() else { return }
            
            let impactAcceleration = CollisionAcceleration(x: impactAccelerationX, y: impactAccelerationY, z: impactAccelerationZ)
            
            guard let impactAxisDict = dict[MessageKeys.impactAxis]?.dictValue() else { return }
            guard let impactAxisX = impactAxisDict[MessageKeys.x]?.boolValue() else { return }
            guard let impactAxisY = impactAxisDict[MessageKeys.y]?.boolValue() else { return }
            
            let impactAxis = CollisionAxis(x: impactAxisX, y: impactAxisY)
            
            guard let impactPowerDict = dict[MessageKeys.impactPower]?.dictValue() else { return }
            guard let impactPowerX = impactPowerDict[MessageKeys.x]?.doubleValue() else { return }
            guard let impactPowerY = impactPowerDict[MessageKeys.y]?.doubleValue() else { return }
            
            let impactPower = CollisionPower(x: impactPowerX, y: impactPowerY, z: nil)
            
            guard let impactSpeed = dict[MessageKeys.impactSpeed]?.doubleValue() else { return }
            guard let timestamp: TimeInterval = dict[MessageKeys.timestamp]?.doubleValue() else { return }
            
            let data = CollisionDataCommandResponse(impactAcceleration: impactAcceleration, impactAxis: impactAxis, impactPower: impactPower, impactSpeed: impactSpeed, timestamp: timestamp)
            
            collisionListeners.forEach { $0(data) }
            
        case .sensorData:
            var locator: LocatorSensorData?
            var orientation: AttitudeSensorData?
            var gyro: GyroscopeSensorData?
            var accelerometer: AccelerometerSensorData?
            
            if let locatorDict = dict[MessageKeys.locator]?.dictValue() {
                locator = LocatorSensorData()
                if let positionDict = locatorDict[MessageKeys.position]?.dictValue() {
                    locator?.position = TwoAxisSensorData<Double>()
                    locator?.position?.x = positionDict[MessageKeys.x]?.doubleValue()
                    locator?.position?.y = positionDict[MessageKeys.y]?.doubleValue()
                }
                if let velocityDict = locatorDict[MessageKeys.velocity]?.dictValue() {
                    locator?.velocity = TwoAxisSensorData<Double>()
                    locator?.velocity?.x = velocityDict[MessageKeys.x]?.doubleValue()
                    locator?.velocity?.y = velocityDict[MessageKeys.y]?.doubleValue()
                }
            }
            if let orientationDict = dict[MessageKeys.orientation]?.dictValue() {
                orientation = AttitudeSensorData()
                if let x = orientationDict[MessageKeys.x]?.intValue() {
                    orientation?.yaw = x
                }
                if let y = orientationDict[MessageKeys.y]?.intValue() {
                    orientation?.pitch = y
                }
                if let z = orientationDict[MessageKeys.z]?.intValue() {
                    orientation?.roll = z
                }
            }
            if let gyroDict = dict[MessageKeys.gyro]?.dictValue() {
                gyro = GyroscopeSensorData()
                if let filteredDict = gyroDict[MessageKeys.filtered]?.dictValue() {
                    gyro?.rotationRate = ThreeAxisSensorData<Int>()
                    gyro?.rotationRate?.x = filteredDict[MessageKeys.x]?.intValue()
                    gyro?.rotationRate?.y = filteredDict[MessageKeys.y]?.intValue()
                    gyro?.rotationRate?.z = filteredDict[MessageKeys.z]?.intValue()
                }
                if let rawDict = gyroDict[MessageKeys.raw]?.dictValue() {
                    gyro?.rawRotation = ThreeAxisSensorData<Int>()
                    gyro?.rawRotation?.x = rawDict[MessageKeys.x]?.intValue()
                    gyro?.rawRotation?.y = rawDict[MessageKeys.y]?.intValue()
                    gyro?.rawRotation?.z = rawDict[MessageKeys.z]?.intValue()
                }
            }
            if let accelerometerDict = dict[MessageKeys.accelerometer]?.dictValue() {
                accelerometer = AccelerometerSensorData()
                if let filteredDict = accelerometerDict[MessageKeys.filtered]?.dictValue() {
                    accelerometer?.filteredAcceleration = ThreeAxisSensorData<Double>()
                    accelerometer?.filteredAcceleration?.x = filteredDict[MessageKeys.x]?.doubleValue()
                    accelerometer?.filteredAcceleration?.y = filteredDict[MessageKeys.y]?.doubleValue()
                    accelerometer?.filteredAcceleration?.z = filteredDict[MessageKeys.z]?.doubleValue()
                }
                if let rawDict = accelerometerDict[MessageKeys.raw]?.dictValue() {
                    accelerometer?.rawAcceleration = ThreeAxisSensorData<Int>()
                    accelerometer?.rawAcceleration?.x = rawDict[MessageKeys.x]?.intValue()
                    accelerometer?.rawAcceleration?.y = rawDict[MessageKeys.y]?.intValue()
                    accelerometer?.rawAcceleration?.z = rawDict[MessageKeys.z]?.intValue()
                }
            }
            
            let data = SensorDataCommandResponseV2(locator: locator, orientation: orientation, gyro: gyro, accelerometer: accelerometer)
            sensorListeners.forEach { $0(data) }
            
        case .freefallDetected:
            freefallListeners.forEach { $0() }
            
        case .landDetected:
            landListeners.forEach { $0() }
            
        default:
            playgroundMessageListeners.forEach { $0(message) }
        }
    }
    */
}
