//
//  Toy.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-08.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol ToyInformation {
    var appVersion: AppVersion? { get }
    var batteryLevel: Double? { get }
    var peripheral: CBPeripheral? { get }
    var onBatteryUpdated: ((_ batteryLevel: Double?) -> Void)? { get set }

    func getPowerState()
}

public class Toy: ToyInformation {
    class var descriptor: String { return "" }
    
    let identifier: UUID
    weak var owner: ToyBox?
    
    init(identifier: UUID, owner: ToyBox) {
        self.identifier = identifier
        self.owner = owner
    }
    
    var appVersion: AppVersion? {
        return nil
    }
    
    var batteryLevel: Double? {
        return nil
    }
    
    var peripheral: CBPeripheral? {
        return nil
    }
    
    var onBatteryUpdated: ((Double?) -> Void)?
    
    open func putAway() { }
    open func connect(callback: @escaping ConnectionCallBack) { }
}

extension ToyInformation  {
    func getPowerState() { }
}
