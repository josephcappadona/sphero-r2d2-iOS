//
//  SpheroV2Toy.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class SpheroV2Toy: Toy, SensorControlProvider, Aimable, Collidable, DriveRollable, ToyCoreCommandListener {
    
    lazy var sensorControl: SensorControl = SensorControlV2(toyCore: self.core)
    let core: SpheroV2ToyCore
    
    var onCollisionDetected: ((CollisionDataCommandResponse) -> Void)?
    
    init(peripheral: CBPeripheral, owner: ToyBox) {
        self.core = SpheroV2ToyCore(peripheral: peripheral)
        super.init(identifier: peripheral.identifier, owner: owner)
        self.core.addAsyncListener(self)
    }
    
    fileprivate func sendRollCommand(heading: UInt16, speed: UInt8, flags: DriveWithHeadingCommand.DriveFlags) {
        core.send(DriveWithHeadingCommand(speed: speed, heading: heading, flags: flags))
    }
    
    override var peripheral: CBPeripheral? {
        return core.peripheral
    }
    
    override var appVersion: AppVersion? {
        return core.appVersion
    }
    
    public func getPowerState() {
        core.send(GetBatteryVoltageCommand())
    }
    
    public func setCollisionDetection(configuration: CollisionConfiguration) {
        core.send(ConfigureCollisionDetectionV2(configuration: configuration))
    }
        
    public func playAnimationBundle(_ bundle: AnimationBundle) {
        core.send(PlayAnimationBundleCommand(animationBundleId: UInt16(bundle.animationId)))
    }
    
    //MARK: Aiming
    //can't put this in an extension, because R2 needs to override start Aiming
    func startAiming() {
        //do what?
    }
    
    func stopAiming() {
        core.send(ResetYawCommand())
    }
    
    //MARK: DriveRollable
    //here for same reason as above
    func roll(heading: Double, speed: Double) {
        let flags: DriveWithHeadingCommand.DriveFlags = speed < 0 ? .reverse : []
        let intSpeed = UInt8(abs(speed).clamp(lowerBound: 0.0, upperBound: 255.0))
        let doubleHeading = speed < 0 ? heading + 180.0 : heading
        let intHeading = UInt16(doubleHeading.positiveRemainder(dividingBy: 360.0))
        
        sendRollCommand(heading: intHeading, speed: intSpeed, flags: flags)
    }
    
    func stopRoll(heading: Double) {
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        sendRollCommand(heading: intHeading, speed: 0, flags: [])
    }
    
    func rotateAim(_ heading: Double) {
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        core.send(DriveWithHeadingCommand(speed: 0, heading: intHeading, flags: [.fastTurnMode]))
    }

    func toyCore(_ toyCore: SpheroV2ToyCore, didReceiveCommandResponse response: CommandResponseV2) {
        switch response {
        case _ as DidSleepResponseV2:
            owner?.disconnect(toy: self)
            
        case let collision as CollisionDataCommandResponse:
            onCollisionDetected?(collision)
            
        default:
            break
        }
    }
    
    override func connect(callback: @escaping ConnectionCallBack) {
        core.prepareConnection(callback: callback)
    }
    
    override func putAway() {
        core.send(GoToSleepCommandV2())
    }
}

public protocol AnimationBundle {
    var animationId: Int { get }
}
