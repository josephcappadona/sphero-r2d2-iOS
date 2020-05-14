//
//  CommandV2.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-23.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol CommandV2 {
    var payload: Data? { get }
    var deviceId: UInt8 { get }
    var commandId: UInt8 { get }
    var commandFlags: CommandV2Flags { get }
}

extension CommandV2 {
    public var commandFlags: CommandV2Flags {
        return .defaultFlags
    }
}

public enum DeviceId: UInt8 {
    case apiProcessor = 0x10
    case systemInfo = 0x11
    case powerInfo = 0x13
    case driving = 0x16
    case animatronics = 0x17
    case sensor = 0x18
    case userIO = 0x1A
}

public enum APIProcessCommandIds: UInt8 {
    case echo = 0x00
}

public enum SystemInfoCommandIds: UInt8 {
    case mainApplicationVersion = 0x00
    case bootloaderVersion = 0x01
}

public enum PowerCommandIds: UInt8 {
    case deepSleep = 0x00
    case sleep = 0x01
    case batteryVoltage = 0x03
    case wake = 0x0D
}

public enum DrivingCommandIds: UInt8 {
    case rawMotor = 0x01
    case resetYaw = 0x06
    case driveWithHeading = 0x07
    case stabilization = 0x0C
}

public enum AnimatronicsCommandIds: UInt8 {
    case animationBundle = 0x05
    case shoulderAction = 0x0D
    case domePosition = 0x0F
    case shoulderActionComplete = 0x26
    case enableShoulderActionCompleteAsync = 0x2A
}

public enum SensorCommandIds: UInt8 {
    case sensorMask = 0x00
    case sensorResponse = 0x02
    case configureCollision = 0x11
    case collisionDetectedAsync = 0x12
    case resetLocator = 0x13
    case enableCollisionAsync = 0x14
}

public enum UserIOCommandIds: UInt8 {
    case allLEDs = 0x0E
    case playAudioFile = 0x07
    case audioVolume = 0x08
    case stopAudio = 0xA
    case testSound = 0x18
}

//MARK: API Commands
protocol APIProcessCommand: CommandV2 { }
extension APIProcessCommand {
    public var deviceId: UInt8 {
        return DeviceId.apiProcessor.rawValue
    }
}

public struct EchoCommand: APIProcessCommand {
    public let commandId: UInt8 = APIProcessCommandIds.echo.rawValue
    public let data: Data
    public init(_ data: Data) {
        self.data = data
    }
    
    public var payload: Data? {
        return nil
    }
}

//MARK: System Info Commands
protocol SystemInfoCommand: CommandV2 { }
extension SystemInfoCommand {
    public var deviceId: UInt8 {
        return DeviceId.systemInfo.rawValue
    }
}

public struct VersioningCommandV2: SystemInfoCommand {
    public let commandId: UInt8 = SystemInfoCommandIds.mainApplicationVersion.rawValue
    
    public var payload: Data? {
        return nil
    }
}

//MARK: Power Info Commands
protocol PowerCommand: CommandV2 { }
extension PowerCommand {
    public var deviceId: UInt8 {
        return DeviceId.powerInfo.rawValue
    }
}

public struct WakeCommandResponse: CommandResponseV2 { }

public struct WakeCommand: PowerCommand {
    public let commandId: UInt8 = PowerCommandIds.wake.rawValue
    
    public var payload: Data? {
        return nil
    }
}

public struct GetBatteryVoltageCommand: PowerCommand {
    public let commandId: UInt8 = PowerCommandIds.batteryVoltage.rawValue
    
    public var payload: Data? {
        return nil
    }
}

public struct DidSleepResponseV2: CommandResponseV2 { }

public struct GoToSleepCommandV2: PowerCommand {
    public let commandId: UInt8 = PowerCommandIds.sleep.rawValue
    
    public var payload: Data? {
        return nil
    }
}

//MARK: Driving Commands
protocol DrivingCommand: CommandV2 { }
extension DrivingCommand {
    public var deviceId: UInt8 {
        return DeviceId.driving.rawValue
    }
}

public struct DriveWithHeadingCommand: DrivingCommand {
    public let commandId: UInt8 = DrivingCommandIds.driveWithHeading.rawValue
    
    public let speed: UInt8
    public let heading: UInt16
    public let flags: DriveFlags
    
    public struct DriveFlags: OptionSet {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        static let reverse = DriveFlags(rawValue: 0x01)
        static let boost = DriveFlags(rawValue: 0x02)
        static let fastTurnMode = DriveFlags(rawValue: 2 << 1)
        static let tankDriveLeftMotorReverse = DriveFlags(rawValue: 2 << 2)
        static let tankDriveRightMotorReverse = DriveFlags(rawValue: 2 << 3)
    }
    
    
    public init(speed: UInt8, heading: UInt16, flags: DriveFlags) {
        self.speed = speed
        self.heading = heading
        self.flags = flags
    }
    
    public var payload: Data? {
        var bytes = [UInt8]()
        bytes.append(speed)
        
        bytes.append(UInt8(heading >> 8 & 0xff))
        bytes.append(UInt8(heading & 0xff))
        bytes.append(flags.rawValue)
        
        return Data(bytes: bytes)
    }
}

public struct RawMotorV2: DrivingCommand {
    public let commandId: UInt8 = DrivingCommandIds.rawMotor.rawValue

    public let leftMotorPower: UInt8
    public let rightMotorPower: UInt8
    public let leftMotorMode: RawMotor.RawMotorMode
    public let rightMotorMode: RawMotor.RawMotorMode

    public init(leftMotorPower: UInt8, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: UInt8, rightMotorMode: RawMotor.RawMotorMode) {
        self.leftMotorMode = leftMotorMode
        self.leftMotorPower = leftMotorPower
        
        self.rightMotorMode = rightMotorMode
        self.rightMotorPower = rightMotorPower
    }
    
    public var payload: Data? {
        return Data(bytes: [
            self.leftMotorMode.rawValue,
            self.leftMotorPower,
            self.rightMotorMode.rawValue,
            self.rightMotorPower
            ])
    }
}

public struct ResetYawCommand: DrivingCommand {
    public let commandId: UInt8 = DrivingCommandIds.resetYaw.rawValue
    
    public var payload: Data? {
        return nil
    }
}

public struct SetStabilizationV2: DrivingCommand {
    public let commandId: UInt8 = DrivingCommandIds.stabilization.rawValue
    
    public let state: SetStabilization.State
    
    public init(state: SetStabilization.State) {
        self.state = state
    }
    
    public var payload: Data? {
        return Data(bytes: [state.rawValue])
    }
    
}

//MARK: Animatronics Commands
protocol AnimatronicsCommand: CommandV2 { }
extension AnimatronicsCommand {
    public var deviceId: UInt8 {
        return DeviceId.animatronics.rawValue
    }
}

public struct SetDomePosition: AnimatronicsCommand {
    public let commandId: UInt8 = AnimatronicsCommandIds.domePosition.rawValue
    public let angle: Float32
    
    public init(angle degrees: Double) {
        self.angle = Float32(degrees)
    }
    
    public var payload: Data? {
        let unsigned = self.angle.bitPattern
        
        var bytes = [UInt8]()
        bytes.append(UInt8((unsigned >> 24) & 0xff))
        bytes.append(UInt8((unsigned >> 16) & 0xff))
        bytes.append(UInt8((unsigned >> 8) & 0xff))
        bytes.append(UInt8(unsigned & 0xff))
        
        return Data(bytes)
    }
}

public struct EnableStanceChangedAsyncCommand: AnimatronicsCommand {
    public let commandId: UInt8 = AnimatronicsCommandIds.enableShoulderActionCompleteAsync.rawValue
    public let enabled: Bool
    
    public init(enabled: Bool) {
        self.enabled = enabled
    }
    public var payload: Data? {
        let data: UInt8 = enabled ? 1 : 0
        return Data(bytes: [data])
    }
}

public struct StanceCommand: AnimatronicsCommand {
    public enum StanceId: UInt8 {
        case stop = 0x00
        case tripod = 0x01
        case bipod = 0x02
        case waddle = 0x03
    }
    
    public let commandId: UInt8 = AnimatronicsCommandIds.shoulderAction.rawValue
    public let stanceId: StanceId
    
    public init(stanceId: StanceId) {
        self.stanceId = stanceId
    }
    
    public var payload: Data? {
        return Data(bytes: [self.stanceId.rawValue])
    }
}

public struct PlayAnimationBundleCommand: AnimatronicsCommand {
    public let commandId: UInt8 = AnimatronicsCommandIds.animationBundle.rawValue
    public let bundleId: UInt16
    
    public init(animationBundleId: UInt16) {
        bundleId = animationBundleId
    }
    
    public var payload: Data? {
        var bytes = [UInt8]()
        bytes.append(UInt8((bundleId >> 8) & 0xff))
        bytes.append(UInt8((bundleId) & 0xff))
        
        return Data(bytes: bytes)
    }
}

//MARK: Sensor Commands
protocol SensorCommands: CommandV2 { }
extension SensorCommands {
    public var deviceId: UInt8 {
        return DeviceId.sensor.rawValue
    }
}

public struct EnableSensorsV2: SensorCommands {
    public let commandId: UInt8 = SensorCommandIds.sensorMask.rawValue
    public let streamingRate: Int
    public let streamingSensors: SensorMaskV2
        
    public init(sensorMask: SensorMaskV2, streamingRate: Int) {
        self.streamingSensors = sensorMask
        self.streamingRate = streamingRate
        
        StreamingDataTrackerV2.sensorMask = sensorMask
    }
    
    public var payload: Data? {
        let sensorRawValue = streamingSensors.rawValue
        
        var bytes = [UInt8]()
        bytes.append(UInt8((streamingRate >> 8) & 0xff))
        bytes.append(UInt8(streamingRate & 0xff))
        bytes.append(UInt8(0))
        bytes.append(UInt8((sensorRawValue >> 24) & 0xff))
        bytes.append(UInt8((sensorRawValue >> 16) & 0xff))
        bytes.append(UInt8((sensorRawValue >> 8) & 0xff))
        bytes.append(UInt8(sensorRawValue & 0xff))
        
        return Data(bytes: bytes)
    }
}

public struct ResetLocator: SensorCommands {
    public let commandId: UInt8 = SensorCommandIds.resetLocator.rawValue
    
    public var payload: Data? {
        return nil
    }
}

public struct ConfigureCollisionDetectionV2: SensorCommands {
    public let commandId: UInt8 = SensorCommandIds.configureCollision.rawValue
    
    public let configuration: CollisionConfiguration
    
    init(configuration: CollisionConfiguration) {
        self.configuration = configuration
    }
    
    public var payload: Data? {
        var scaledDeadZone = configuration.postTimeDeadZone * 100
        scaledDeadZone = max(0, scaledDeadZone)
        scaledDeadZone = min(255, scaledDeadZone)
        let deadZoneByte = UInt8(scaledDeadZone)
        
        let bytes = [
            configuration.detectionMethod.rawValue,
            configuration.xThreshold,
            configuration.xSpeedThreshold,
            configuration.yThreshold,
            configuration.ySpeedThreshold,
            deadZoneByte
        ]
        
        return Data(bytes: bytes)
    }
}

//MARK: User IO Commands
protocol UserIOCommand: CommandV2 { }
extension UserIOCommand {
    public var deviceId: UInt8 {
        return DeviceId.userIO.rawValue
    }
}
public protocol LEDMask {
    var maskValue: UInt16 { get }
}

public enum R2D2Sound: Int {
    case happy
    case cheerful
    case joyful
    case hello
    case excited
    case sad
    case scared
    case cautious
    case scan
    case talking
    
    public var droidSound: PlaySoundCommand.DroidSound {
        switch self {
        case .happy: return .happy
        case .cheerful: return .cheerful
        case .joyful: return .joyful
        case .hello: return .hello
        case .excited: return .excited
        case .scared: return .scared
        case .cautious: return .cautious
        case .scan: return .scan
        case .talking: return .talking
        case .sad: return .sad            
        }
    }
}

public struct PlaySoundCommand: UserIOCommand {
    public let commandId: UInt8 = UserIOCommandIds.playAudioFile.rawValue
    public let playbackMode: AudioPlaybackMode
    public let soundId: DroidSound
    
    public enum AudioPlaybackMode: UInt8 {
        case immediately = 0x00
        case playOnlyIfNotPlaying = 0x01
        case afterCurrent = 0x02
    }
    
    public enum DroidSound: UInt16 {
        case cheerful = 3438
        case joyful = 3460
        case happy = 3410
        case hello = 2861
        case excited = 2615
        case scared = 1797
        case talking = 2241
        case cautious = 3200
        case scan = 2797
        case sad = 3619
    }
    
    public init(sound: DroidSound, playbackMode: AudioPlaybackMode) {
        self.playbackMode = playbackMode
        self.soundId = sound
    }
    
    public var payload: Data? {
        var bytes = [UInt8]()
        
        bytes.append(UInt8((soundId.rawValue >> 8) & 0xff))
        bytes.append(UInt8(soundId.rawValue & 0xff))
        bytes.append(playbackMode.rawValue)
        return Data(bytes: bytes)
    }
}

public struct SetAudioVolume: UserIOCommand {
    public let commandId: UInt8 = UserIOCommandIds.audioVolume.rawValue
    public let volume: UInt8
    
    public init(volume: UInt8) {
        self.volume = volume
    }
    
    
    public var payload: Data? {
        return Data(bytes: [self.volume])
    }
}

public struct TestAudioCommand: UserIOCommand {
    public let commandId: UInt8  = UserIOCommandIds.testSound.rawValue
    
    public var payload: Data? {
        return nil
    }
}

public struct StopAudioCommand: UserIOCommand {
    public let commandId: UInt8  = UserIOCommandIds.stopAudio.rawValue
    
    public var payload: Data? {
        return nil
    }
}

public struct SetAllLEDCommand: UserIOCommand {
    public let commandId: UInt8 = UserIOCommandIds.allLEDs.rawValue
    public let color: UIColor?
    public let brightness: UInt8?
    public let ledMask: LEDMask
    
    public init(ledMask mask: LEDMask, color: UIColor) {
        self.ledMask = mask
        self.color = color
        self.brightness = nil
    }
    
    public init(ledMask mask: LEDMask, brightness: UInt8) {
        self.ledMask = mask
        self.color = nil
        self.brightness = brightness
    }
    
    public var payload: Data? {
        var bytes = [UInt8]()
        bytes.append(UInt8((ledMask.maskValue >> 8) & 0xff))
        bytes.append(UInt8(ledMask.maskValue & 0xff))
        
        if let color = color {
            var r: CGFloat = 0.0
            var g: CGFloat = 0.0
            var b: CGFloat = 0.0
            
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            bytes.append(UInt8(r * 255))
            bytes.append(UInt8(g * 255))
            bytes.append(UInt8(b * 255))
        }
        
        if let brightness = brightness {
            bytes.append(brightness)
        }
        
        return Data(bytes: bytes)
    }
}
