//
//  LiveViewController+Messages.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-28.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

extension LiveViewController: PlaygroundLiveViewMessageHandler {
    typealias MessageDict = Dictionary<String, PlaygroundSupport.PlaygroundValue>
    
    public func liveViewMessageConnectionOpened() {
        // This is run when the user presses "Run Code" in the playgrounds app.
        isLiveViewMessageConnectionOpened = true
        
        // Show aiming controller
        if shouldPresentAim && connectedToy != nil {
            showAimingController()
        }
        
        if shouldAutomaticallyConnectToToy && connectedToy == nil {
            connectionHintArrowView.show()
        }
        
        // Fade out our overlay if we have one
        if overlayView != nil {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5) {
                    self.overlayView?.alpha = 0.0
                }
            }
        }
        
        roller?.start()
    }
    
    public func liveViewMessageConnectionClosed() {
        // This is run when the user presses the stop button.
        isLiveViewMessageConnectionOpened = false
        
        connectedToy?.stopRoll(heading: 0.0)
        
        //stop any waddling
        connectedToy?.setStance(.bipod)
        
        didReceiveRollMessage(heading: 0.0, speed: 0.0)
        
        // Dismiss aiming view
        if let aimingViewController = aimingViewController {
            removeModalViewController(aimingViewController) { (_) in
                self.aimingViewController = nil
            }
        }
        
        connectionHintArrowView.hide()
        roller?.pause()
    }
    
    public func receive(_ message: PlaygroundValue) {
        guard let dict = message.dictValue(),
            let typeIdValue = dict[MessageKeys.type],
            let typeId = MessageTypeId(value: typeIdValue) else { return }
        
        switch typeId {
        case .roll:
            sendRoll(dict: dict)
            
        case .stopRoll:
            sendStopRoll(dict: dict)
            
        case .setMainLed:
            sendSetMainLed(dict: dict)
            
        case .setHeadLed:
            sendSetHeadLed(dict: dict)

        case .setFrontPSILed:
            sendSetFrontPSILed(dict: dict)
            
        case .setBackPSILed:
            sendSetBackPSILed(dict: dict)
            
        case .setHoloProjectorLed:
            sendSetHoloProjectorLED(dict: dict)
            
        case .setLogicDisplayLed:
            sendSetLogicDisplayLED(dict: dict)
            
        case .setStance:
            sendStance(dict: dict)
            
        case .setDomePosition:
            sendHeadPosition(dict: dict)
            
        case .playAnimation:
            sendPlayAnimation(dict: dict)
            
        case .playSound:
            sendPlaySound(dict: dict)
            
        case .startAiming:
            connectedToy?.startAiming()
            
        case .stopAiming:
            connectedToy?.stopAiming()
            
        case .rotateAim:
            sendRotateAim(dict: dict)
            
        case .connect:
            if connectedToy == nil {
                if !shouldAutomaticallyConnectToToy {
                    connectToNearest()
                }
            } else if shouldPresentAim {
                showAimingController()
            } else {
                sendToyReadyMessage()
            }
            
        case .enableSensors:
            sendEnableSensors(dict: dict)
            
        case .resetLocator:
            sendResetLocator(dict: dict)
            
        case .playAssessmentSound:
            playSound(dict: dict)
            
        case .setCollisionDetection:
            sendSetCollisionDetection(dict: dict)
            
        case .setBackLed:
            sendSetBackLed(dict: dict)
            
        case .setStabilization:
            sendSetStabilization(dict: dict)
            
        default:
            break
        }
        
        // This method can't be overridden (yet) because it's defined in an extension.
        // Instead, allow subclasses to override onReceive and pass messages to that too.
        onReceive(message: message)
    }
    
    func playSound(dict: MessageDict) {
        guard let passSound = dict[MessageKeys.assessmentSoundKey]?.intValue() else { return }
        playAssessmentSound(playPassSound: (passSound == 0 ? false : true))
    }
    
    func sendResetLocator(dict: MessageDict) {
        connectedToy?.sensorControl?.resetLocator()
    }
    
    func sendCollisionMessage(data: CollisionData) {
        let message = PlaygroundValue.dictionary([
            MessageKeys.type: MessageTypeId.collisionDetected.playgroundValue(),
            MessageKeys.impactAcceleration: .dictionary([
                MessageKeys.x: .floatingPoint(data.impactAcceleration.x),
                MessageKeys.y: .floatingPoint(data.impactAcceleration.y),
                MessageKeys.z: .floatingPoint(data.impactAcceleration.z),
                ]),
            MessageKeys.impactPower: .dictionary([
                MessageKeys.x: .floatingPoint(data.impactPower.x),
                MessageKeys.y: .floatingPoint(data.impactPower.y),
                ]),
            MessageKeys.impactAxis: .dictionary([
                MessageKeys.x: .boolean(data.impactAxis.x),
                MessageKeys.y: .boolean(data.impactAxis.y),
                ]),
            MessageKeys.impactSpeed: .floatingPoint(data.impactSpeed),
            MessageKeys.timestamp: .floatingPoint(data.timestamp)
            ])
        
        sendMessageToContents(message)
    }
    
    func sendSensorDataMessage(data: SensorControlData) {
        var dict: MessageDict = [
            MessageKeys.type: MessageTypeId.sensorData.playgroundValue()
        ]
        
        if let locator = data.locator {
            var sensorDict: MessageDict = [:]
            if let position = locator.position {
                var positionDict: MessageDict = [:]
                if let x = position.x {
                    positionDict[MessageKeys.x] = .floatingPoint(x)
                }
                if let y = position.y {
                    positionDict[MessageKeys.y] = .floatingPoint(y)
                }
                sensorDict[MessageKeys.position] = .dictionary(positionDict)
            }
            if let velocity = data.locator?.velocity {
                var velocityDict: MessageDict = [:]
                if let x = velocity.x {
                    velocityDict[MessageKeys.x] = .floatingPoint(x)
                }
                if let y = velocity.y {
                    velocityDict[MessageKeys.y] = .floatingPoint(y)
                }
                sensorDict[MessageKeys.velocity] = .dictionary(velocityDict)
            }
            dict[MessageKeys.locator] = .dictionary(sensorDict)
        }
        
        if let orientation = data.orientation {
            var sensorDict: MessageDict = [:]
            if let x = orientation.yaw {
                sensorDict[MessageKeys.x] = .integer(x)
            }
            if let y = orientation.pitch {
                sensorDict[MessageKeys.y] = .integer(y)
            }
            if let z = orientation.roll {
                sensorDict[MessageKeys.z] = .integer(z)
            }
            dict[MessageKeys.orientation] = .dictionary(sensorDict)
        }
        
        if let gyro = data.gyro {
            var sensorDict: MessageDict = [:]
            if let filtered = gyro.rotationRate {
                var filteredDict: MessageDict = [:]
                if let x = filtered.x {
                    filteredDict[MessageKeys.x] = .integer(x / 10)
                }
                if let y = filtered.y {
                    filteredDict[MessageKeys.y] = .integer(y / 10)
                }
                if let z = filtered.z {
                    filteredDict[MessageKeys.z] = .integer(z / 10)
                }
                sensorDict[MessageKeys.filtered] = .dictionary(filteredDict)
            }
            if let raw = gyro.rawRotation {
                var rawDict: MessageDict = [:]
                if let x = raw.x {
                    rawDict[MessageKeys.x] = .integer(x / 10)
                }
                if let y = raw.y {
                    rawDict[MessageKeys.y] = .integer(y / 10)
                }
                if let z = raw.z {
                    rawDict[MessageKeys.z] = .integer(z / 10)
                }
                sensorDict[MessageKeys.raw] = .dictionary(rawDict)
            }
            dict[MessageKeys.gyro] = .dictionary(sensorDict)
        }
        
        if let accelerometer = data.accelerometer {
            var sensorDict: MessageDict = [:]
            if let filtered = accelerometer.filteredAcceleration {
                var filteredDict: MessageDict = [:]
                if let x = filtered.x {
                    filteredDict[MessageKeys.x] = .floatingPoint(x)
                }
                if let y = filtered.y {
                    filteredDict[MessageKeys.y] = .floatingPoint(y)
                }
                if let z = filtered.z {
                    filteredDict[MessageKeys.z] = .floatingPoint(z)
                }
                sensorDict[MessageKeys.filtered] = .dictionary(filteredDict)
            }
            if let raw = accelerometer.rawAcceleration {
                var rawDict: MessageDict = [:]
                if let x = raw.x {
                    rawDict[MessageKeys.x] = .integer(x)
                }
                if let y = raw.y {
                    rawDict[MessageKeys.y] = .integer(y)
                }
                if let z = raw.z {
                    rawDict[MessageKeys.z] = .integer(z)
                }
                sensorDict[MessageKeys.raw] = .dictionary(rawDict)
            }
            dict[MessageKeys.accelerometer] = .dictionary(sensorDict)
        }
        
        let message = PlaygroundValue.dictionary(dict)
        sendMessageToContents(message)
    }
    
    func sendToyReadyMessage() {
        guard let toy = connectedToy?.toy else { return }
    
        guard !requiresFirmwareUpdate(for: toy) else { return }
        
        let descriptor = type(of: toy).descriptor

        sendMessageToContents(
            .dictionary([
                MessageKeys.type: MessageTypeId.toyReady.playgroundValue(),
                MessageKeys.descriptor: .string(descriptor)
                ])
        )
    }
    
    func sendRoll(dict: MessageDict) {
        guard let speed = dict[MessageKeys.speed]?.doubleValue(),
            let heading = dict[MessageKeys.heading]?.doubleValue() else { return }
        
        connectedToy?.roll(heading: heading, speed: speed)
        didReceiveRollMessage(heading: heading, speed: speed)
    }
    
    func sendRotateAim(dict: MessageDict) {
        guard let heading = dict[MessageKeys.heading]?.doubleValue() else { return }
        
        connectedToy?.rotateAim(heading)
    }
    
    func sendStopRoll(dict: MessageDict) {
        guard let heading = dict[MessageKeys.heading]?.doubleValue() else { return }
        
        connectedToy?.stopRoll(heading: heading)
        didReceiveRollMessage(heading: heading, speed: 0.0)
    }
    
    func sendPlayAnimation(dict: MessageDict) {
        guard let bundleId = dict[MessageKeys.animationBundleId]?.intValue(),
            let animation = R2D2Animations(bundleId: bundleId) else { return }
        
        connectedToy?.playAnimationBundle(animation)
    }
    
    func sendPlaySound(dict: MessageDict) {
        guard let soundId = dict[MessageKeys.soundId]?.intValue(),
            let sound = R2D2Sound(rawValue: soundId),
            let playbackId = dict[MessageKeys.playbackMode]?.intValue(),
            let playbackMode = PlaySoundCommand.AudioPlaybackMode(rawValue: UInt8(playbackId)) else { return }
        
        connectedToy?.playSound(sound.droidSound, playbackMode: playbackMode)
    }
    
    func sendHeadPosition(dict: MessageDict) {
        guard let angle = dict[MessageKeys.domePosition]?.doubleValue() else { return }
        
        connectedToy?.setDomePosition(angle: angle)
        didReceiveSetDomePositionMessage(angle: angle)
    }
    
    func sendSetMainLed(dict: MessageDict) {
        guard let color = dict[MessageKeys.mainLedColor]?.colorValue() else { return }
        
        connectedToy?.setMainLed(color: color)
        didReceiveSetMainLedMessage(color: color)
    }
    
    func sendSetFrontPSILed(dict: MessageDict) {
        guard let color = dict[MessageKeys.frontPSILedColor]?.colorValue(), let psiColor = FrontPSIColor(color: color) else { return }
        
        connectedToy?.setFrontPSILed(color: psiColor)
        didReceiveSetFrontPSILedMessage(color: color)
    }
    
    func sendSetBackLed(dict: MessageDict) {
        guard let brightness = dict[MessageKeys.brightness]?.doubleValue() else { return }
        
        connectedToy?.setBackLed(brightness: brightness)
    }
    
    func sendSetBackPSILed(dict: MessageDict) {
        guard let color = dict[MessageKeys.backPSILedColor]?.colorValue(), let psiColor = BackPSIColor(color: color)  else { return }
        
        connectedToy?.setBackPSILed(color: psiColor)
        didReceiveSetBackPSILedMessage(color: color)
    }
    
    func sendSetHeadLed(dict: MessageDict) {
        guard let brightness = dict[MessageKeys.brightness]?.doubleValue() else { return }
        
        connectedToy?.setHeadLed(brightness: brightness)
    }
    
    func sendSetHoloProjectorLED(dict: MessageDict) {
        guard let brightness = dict[MessageKeys.brightness]?.doubleValue() else { return }
        
        connectedToy?.setHoloProjectorLed(brightness: brightness)
        didReceiveSetHoloProjectorLedMesssage(brightness: brightness)
    }
    
    func sendSetLogicDisplayLED(dict: MessageDict) {
        guard let brightness = dict[MessageKeys.brightness]?.doubleValue() else { return }
        
        connectedToy?.setLogicDisplayLeds(brightness: brightness)
        didReceiveSetLogicDiplayLedMesssage(brightness: brightness)
    }
    
    func sendStance(dict: MessageDict) {
        guard let stanceId = dict[MessageKeys.stance]?.intValue(),
            let stance = StanceCommand.StanceId(rawValue: UInt8(stanceId)) else { return }
        
        connectedToy?.setStance(stance)
        didReceiveSetStanceMessage(stance: stance)
    }
    
    func sendSetStabilization(dict: MessageDict) {
        guard let stateRaw = dict[MessageKeys.state]?.intValue(),
            let state = StabilizationState(rawValue: UInt8(stateRaw))
            else { return }
        
        connectedToy?.setStabilization(state: state)
    }
    
    func sendEnableSensors(dict: MessageDict) {
        guard let mask = dict[MessageKeys.sensorMask]?.arrayValue() else { return }
        //TODO: figure out how to make this look nice?
        let sensorMasks = mask.map { SensorMaskValues(rawValue: $0.intValue()!)! }
        
        if !sensorMasks.contains(where: { $0 == SensorMaskValues.off }) {
            if let interval = dict[MessageKeys.sensorInterval]?.intValue() {
                connectedToy?.sensorControl?.interval = interval
            }
            
            connectedToy?.sensorControl?.enable(sensors: sensorMasks)
            didReceiveEnableSensorsMessage(sensors: sensorMasks)
        } else {
            connectedToy?.sensorControl?.disable()
            didReceiveEnableSensorsMessage(sensors: [])
        }
    }
    
    func sendSetCollisionDetection(dict: MessageDict) {
        guard let rawMethod = dict[MessageKeys.detectionMethod]?.intValue(),
            let detectionMethod = CollisionConfiguration.DetectionMethod(rawValue: UInt8(rawMethod)),
            let threshold = dict[MessageKeys.threshold]?.dictValue(),
            let xThreshold = threshold[MessageKeys.x]?.intValue(),
            let yThreshold = threshold[MessageKeys.y]?.intValue(),
            let speedThreshold = dict[MessageKeys.speedThreshold]?.dictValue(),
            let xSpeedThreshold = speedThreshold[MessageKeys.x]?.intValue(),
            let ySpeedThreshold = speedThreshold[MessageKeys.y]?.intValue(),
            let postTimeDeadZone = dict[MessageKeys.postTimeDeadZone]?.doubleValue() else { return }
        
        let configuration = CollisionConfiguration(
            detectionMethod: detectionMethod,
            xThreshold: UInt8(xThreshold),
            xSpeedThreshold: UInt8(xSpeedThreshold),
            yThreshold: UInt8(yThreshold),
            ySpeedThreshold: UInt8(ySpeedThreshold),
            postTimeDeadZone: postTimeDeadZone
        )
        
        connectedToy?.setCollisionDetection(configuration: configuration)
        didReceiveSetCollisionDetectionMesssage(configuration: configuration)
    }
    
    func sendFreefallMessage() {
        let message = PlaygroundValue.dictionary([
            MessageKeys.type: MessageTypeId.freefallDetected.playgroundValue()
            ])
        
        sendMessageToContents(message)
    }
    
    func sendLandMessage() {
        let message = PlaygroundValue.dictionary([
            MessageKeys.type: MessageTypeId.landDetected.playgroundValue()
            ])
        
        sendMessageToContents(message)
    }
}
