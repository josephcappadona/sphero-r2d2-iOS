//
//  AnyToy.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-25.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

internal class AnyToy: ToyInformation, RollableToy, AimableToy, CollidableToy, AstromechToy, MainLedToy, BackLedToy, HeadLedToy, AnimatableToy, StabilizationToy, FrontLedToy, BackLedColorToy, MatrixLedToy {
    let toy: Toy
    
    var sensorControl: SensorControl?
    
    var onBatteryUpdated: ((Double?) -> Void)?
    
    public init(toy: Toy) {
        self.toy = toy
        self.sensorControl = (toy as? SensorControlProvider)?.sensorControl
    }
    
    var peripheral: CBPeripheral? {
        return toy.peripheral
    }

    var batteryLevel: Double? {
        return toy.batteryLevel
    }

    var appVersion: AppVersion? {
        return toy.appVersion
    }
    
    func getPowerState() {
        toy.getPowerState()
    }
    
    var onCollisionDetected: ((CollisionData) -> Void)? {
        get {
            return (toy as? CollidableToy)?.onCollisionDetected
        }
        
        set {
            (toy as? CollidableToy)?.onCollisionDetected = newValue
        }
    }

    func startAiming() {
        (toy as? AimableToy)?.startAiming()
    }

    func stopAiming() {
        (toy as? AimableToy)?.stopAiming()
    }
    
    func rotateAim(_ heading: Double) {
        (toy as? AimableToy)?.rotateAim(heading)
    }
    
    func setCollisionDetection(configuration: CollisionConfiguration) {
        (toy as? CollidableToy)?.setCollisionDetection(configuration: configuration)
    }
    
    func roll(heading: Double, speed: Double, rollType: Roll.RollType = .roll, direction: Roll.RollDirection = .forward) {
        (toy as? RollableToy)?.roll(heading: heading, speed: speed, rollType: rollType, direction: direction)
    }
    
    func stopRoll(heading: Double) {
        (toy as? RollableToy)?.stopRoll(heading: heading)
    }
    
    func setDomePosition(angle degrees: Double) {
        (toy as? AstromechToy)?.setDomePosition(angle: degrees)
    }
    
    func setStance(_ stance: StanceCommand.StanceId) {
        (toy as? AstromechToy)?.setStance(stance)
    }
    
    func setFrontPSILed(color: FrontPSIColor) {
        (toy as? AstromechToy)?.setFrontPSILed(color: color)
    }
    
    func setBackPSILed(color: BackPSIColor) {
        (toy as? AstromechToy)?.setBackPSILed(color: color)
    }
    
    func setHoloProjectorLed(brightness: Double) {
        (toy as? AstromechToy)?.setHoloProjectorLed(brightness: brightness)
    }
    
    func setLogicDisplayLeds(brightness: Double) {
        (toy as? AstromechToy)?.setLogicDisplayLeds(brightness: brightness)
    }
    
    func setAudioVolume(_ volume: Int) {
        (toy as? AstromechToy)?.setAudioVolume(volume)
    }
    
    func setStanceChangedNotifications(enabled: Bool) {
        (toy as? AstromechToy)?.setStanceChangedNotifications(enabled: enabled)
    }
    
    func playSound(_ soundId: PlaySoundCommand.DroidSound, playbackMode: PlaySoundCommand.AudioPlaybackMode) {
        (toy as? AstromechToy)?.playSound(soundId, playbackMode: playbackMode)
    }
    
    func playTestAudio() {
        (toy as? AstromechToy)?.playTestAudio()
    }
    
    func playAnimationBundle(_ bundleId: AnimationBundle) {
        (toy as? AnimatableToy)?.playAnimationBundle(bundleId)
    }
    
    func stopAudio() {
        (toy as? AstromechToy)?.stopAudio()
    }
    
    func setMainLed(color: UIColor) {
        (toy as? MainLedToy)?.setMainLed(color: color)
    }
    
    func setHeadLed(brightness: Double) {
        (toy as? HeadLedToy)?.setHeadLed(brightness: brightness)
    }
    
    func setBackLed(brightness: Double) {
        (toy as? BackLedToy)?.setBackLed(brightness: brightness)
    }
    
    func setBackLed(color: UIColor) {
        (toy as? BackLedColorToy)?.setBackLed(color: color)
    }
    
    func setFrontLed(color: UIColor) {
        (toy as? FrontLedToy)?.setFrontLed(color: color)
    }
    
    func setStabilization(state: StabilizationState) {
        (toy as? StabilizationToy)?.setStabilization(state: state)
    }
    
    func setMatrix(color: UIColor) {
        (toy as? MatrixLedToy)?.setMatrix(color: color)
    }
    
    func setMatrix(rotation: MatrixRotation) {
        (toy as? MatrixLedToy)?.setMatrix(rotation: rotation)
    }
    
    func drawMatrixLine(from startPixel: Pixel, to endPixel: Pixel, color: UIColor) {
        (toy as? MatrixLedToy)?.drawMatrixLine(from: startPixel, to: endPixel, color: color)
    }
    
    func drawMatrix(pixel: Pixel, color: UIColor) {
        (toy as? MatrixLedToy)?.drawMatrix(pixel: pixel, color: color)
    }
    
    func drawMatrix(fillFrom startPixel: Pixel, to endPixel: Pixel, color: UIColor) {
        (toy as? MatrixLedToy)?.drawMatrix(fillFrom: startPixel, to: endPixel, color: color)
    }
    
    func clearMatrix() {
        (toy as? MatrixLedToy)?.clearMatrix()
    }
    
    func scrollMatrix(text: String, color: UIColor, speed: Int, loop: ScrollingTextLoopMode) {
        (toy as? MatrixLedToy)?.scrollMatrix(text: text, color: color, speed: speed, loop: loop)
    }
}

internal protocol RollableToy {
    func roll(heading: Double, speed: Double, rollType: Roll.RollType, direction: Roll.RollDirection)
    func stopRoll(heading: Double)
}

extension SpheroV1Toy: RollableToy { }
extension SpheroV2Toy: RollableToy { }

internal protocol AimableToy {
    func startAiming()
    func stopAiming()
    func rotateAim(_:Double)
}

extension SpheroV1Toy: AimableToy { }
extension SpheroV2Toy: AimableToy { }

internal protocol CollidableToy: AnyObject {
    func setCollisionDetection(configuration: CollisionConfiguration)
    var onCollisionDetected: ((CollisionData) -> Void)? { get set }
}

extension SpheroV1Toy: CollidableToy { }
extension SpheroV2Toy: CollidableToy { }

internal protocol AstromechToy {
    func setDomePosition(angle degrees: Double)
    func setStance(_ stance: StanceCommand.StanceId)
    func setFrontPSILed(color: FrontPSIColor)
    func setBackPSILed(color: BackPSIColor)
    func setHoloProjectorLed(brightness: Double)
    func setLogicDisplayLeds(brightness: Double)
    func setStanceChangedNotifications(enabled: Bool)
    func setAudioVolume(_ volume: Int)
    func playSound(_ soundId: PlaySoundCommand.DroidSound, playbackMode: PlaySoundCommand.AudioPlaybackMode)
    func playTestAudio()
    func stopAudio()
}

extension R2D2Toy: AstromechToy { }

internal protocol MainLedToy {
    func setMainLed(color: UIColor)
}

extension SpheroV1Toy: MainLedToy { }
extension BB9EToy: MainLedToy { }
extension BoltToy: MainLedToy { }

internal protocol HeadLedToy {
    func setHeadLed(brightness: Double)
}

extension BB9EToy: HeadLedToy { }

internal protocol BackLedToy {
    func setBackLed(brightness: Double)
}
extension SpheroV1Toy: BackLedToy { }
extension BB9EToy: BackLedToy { }

internal protocol BackLedColorToy {
    func setBackLed(color: UIColor)
}

extension BoltToy: BackLedColorToy { }

internal protocol FrontLedToy {
    func setFrontLed(color: UIColor)
}

extension BoltToy: FrontLedToy { }

internal protocol AnimatableToy {
    func playAnimationBundle(_ bundleId: AnimationBundle)
}

extension R2D2Toy: AnimatableToy { }
extension BB9EToy: AnimatableToy { }

internal protocol StabilizationToy {
    func setStabilization(state: StabilizationState)
}

extension SpheroV1Toy: StabilizationToy { }
extension BB9EToy: StabilizationToy { }

internal protocol MatrixLedToy {
    func drawMatrix(pixel: Pixel, color: UIColor)
    func drawMatrixLine(from startPixel: Pixel, to endPixel: Pixel, color: UIColor)
    func drawMatrix(fillFrom startPixel: Pixel, to endPixel: Pixel, color: UIColor)
    func setMatrix(color: UIColor)
    func setMatrix(rotation: MatrixRotation)
    func clearMatrix()
    func scrollMatrix(text: String, color: UIColor, speed: Int, loop: ScrollingTextLoopMode)
}

extension BoltToy: MatrixLedToy { }
extension BoltToy: StabilizationToy { }
