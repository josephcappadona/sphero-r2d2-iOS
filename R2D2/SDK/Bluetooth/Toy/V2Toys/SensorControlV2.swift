//
//  SensorControlV2.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-29.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

public struct SensorMaskV2: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let off = SensorMaskV2(rawValue: 0)
    private static let velocityY = SensorMaskV2(rawValue: 1 << 3)
    private static let velocityX = SensorMaskV2(rawValue: 1 << 4)
    private static let locatorY = SensorMaskV2(rawValue: 1 << 5)
    private static let locatorX = SensorMaskV2(rawValue: 1 << 6)
    
    private static let gyroZFilteredV2 = SensorMaskV2(rawValue: 1 << 10)
    private static let gyroYFilteredV2 = SensorMaskV2(rawValue: 1 << 11)
    private static let gyroXFilteredV2 = SensorMaskV2(rawValue: 1 << 12)
    
    // Need this for V2.1
    private static let gyroZFilteredV21 = SensorMaskV2(rawValue: 1 << 23)
    private static let gyroYFilteredV21 = SensorMaskV2(rawValue: 1 << 24)
    private static let gyroXFilteredV21 = SensorMaskV2(rawValue: 1 << 25)
    
    private static let accelerometerZFiltered = SensorMaskV2(rawValue: 1 << 13)
    private static let accelerometerYFiltered = SensorMaskV2(rawValue: 1 << 14)
    private static let accelerometerXFiltered = SensorMaskV2(rawValue: 1 << 15)
    private static let imuYawAngleFiltered = SensorMaskV2(rawValue: 1 << 16)
    private static let imuRollAngleFiltered = SensorMaskV2(rawValue: 1 << 17)
    private static let imuPitchAngleFiltered = SensorMaskV2(rawValue: 1 << 18)
    
    public static let gyroFilteredAllV2 = SensorMaskV2(rawValue: gyroZFilteredV2.rawValue | gyroYFilteredV2.rawValue | gyroXFilteredV2.rawValue)
    public static let gyroFilteredAllV21 = SensorMaskV2(rawValue: gyroZFilteredV21.rawValue | gyroYFilteredV21.rawValue | gyroXFilteredV21.rawValue)  // Need this for V21
    public static let imuAnglesFilteredAll = SensorMaskV2(rawValue: imuYawAngleFiltered.rawValue | imuRollAngleFiltered.rawValue | imuPitchAngleFiltered.rawValue)
    public static let accelerometerFilteredAll = SensorMaskV2(rawValue: accelerometerZFiltered.rawValue | accelerometerYFiltered.rawValue | accelerometerXFiltered.rawValue)
    public static let locatorAll = SensorMaskV2(rawValue: locatorX.rawValue | locatorY.rawValue | velocityX.rawValue | velocityY.rawValue)
}

class SensorControlV2: SensorControl {
    weak var toyCore: SpheroV2ToyCore?
    var interval = SensorControlDefaults.interval
    let sensorVersion: SensorVersions
    var onDataReady: ((_ sensorData: SensorControlData) -> Void)?
    
    var onFreefallDetected: (() -> Void)? {
        //pipe this to our free fall detector
        get {
            return freefallDetector.onFreefallDetected
        }
        set {
            freefallDetector.onFreefallDetected = newValue
        }
    }
    
    var onLandingDetected: (() -> Void)? {
        //pipe this to our free fall detector
        get {
            return freefallDetector.onLandingDetected
        }
        set {
            freefallDetector.onLandingDetected = newValue
        }
    }
    
    fileprivate var extendedStreamingMask: SensorMaskV2?
    fileprivate var v2SensorMask: SensorMaskV2?
    fileprivate let freefallDetector = FreefallLandingDetector()
    
    public init(toyCore: SpheroV2ToyCore, sensorVersion: SensorVersions) {
        self.toyCore = toyCore
        self.sensorVersion = sensorVersion
        self.toyCore?.addAsyncListener(self)
    }
    
    func enable(sensors sensorMask: SensorMask) {
        var v2SensorMask: SensorMaskV2 = []
        var gyroMask: SensorMaskV2 = []
        
        for sensorVal in sensorMask {
            switch sensorVal {
            case .locator:
                v2SensorMask.insert(.locatorAll)
                
            case .gyro:
                
                switch sensorVersion {
                case .v2:
                    v2SensorMask.insert(.gyroFilteredAllV2)
                case .v21:
                    gyroMask.insert(.gyroFilteredAllV21)
                }
                
            case .orientation:
                v2SensorMask.insert(.imuAnglesFilteredAll)
                
            case .accelerometer:
                v2SensorMask.insert(.accelerometerFilteredAll)
                
            case .off:
                v2SensorMask.insert(.off)
            }
        }
        
        self.v2SensorMask = v2SensorMask
        toyCore?.send(EnableSensorsV2(sensorMask: v2SensorMask, streamingRate: interval))
        
        // Need this for V2.1
        if !gyroMask.isEmpty {
            extendedStreamingMask = gyroMask
            toyCore?.send(SetExtendedStreamingMask(extendedStreamingMask: gyroMask))
        }
        
    }
    
    func disable() {
        toyCore?.send(EnableSensorsV2(sensorMask: [.off], streamingRate: 0))
    }
    
    func resetLocator() {
        toyCore?.send(ResetLocator())
    }
}

extension SensorControlV2: ToyCoreCommandListener {
    func toyCore(_ toyCore: SpheroV2ToyCore, didReceiveCommandResponse response: CommandResponseV2) {
        if let _ = response as? SensorMaskCommandResponse {
            guard let v2SensorMask = v2SensorMask else { return }
            StreamingDataTrackerV2.sensorMask = v2SensorMask
        } else if let _ = response as? SensorExtendedMaskCommandResponse {
            guard let extendedStreamingMask = extendedStreamingMask else { return }
            StreamingDataTrackerV2.sensorMask = StreamingDataTrackerV2.sensorMask?.union(extendedStreamingMask)
        } else if let sensorData = response as? SensorDataCommandResponseV2 {
            freefallDetector.checkFreefallStatus(sensorData: sensorData)
            onDataReady?(sensorData)
        }
    }
}

public enum SensorVersions {
    case v2
    case v21
}
