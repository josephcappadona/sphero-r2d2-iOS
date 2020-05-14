//
//  ToyProtocols.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-14.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

protocol DriveRollable {
    func roll(heading: Double, speed: Double)
    func stopRoll(heading: Double)
}

protocol Aimable {
    func startAiming()
    func stopAiming()
    func rotateAim(_ heading: Double)
}

protocol Collidable {
    func setCollisionDetection(configuration: CollisionConfiguration)
    
    var onCollisionDetected: ((_ collisionData: CollisionDataCommandResponse) -> Void)? { get set }
}

protocol SensorControlProvider {
    var sensorControl: SensorControl { get }
}