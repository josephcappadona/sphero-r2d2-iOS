//
//  ToyBox.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-08.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import PlaygroundBluetooth

public enum ConnectionError: Error {
    case noToyFound
    case peripheralFailed(error: Error?)
}

public protocol ToyBoxListener: class {
    func toyBoxReady(_ toyBox: ToyBox)
    func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor)
    func toyBox(_ toyBox: ToyBox, willReady descriptor: ToyDescriptor)
    func toyBox(_ toyBox: ToyBox, readied toy: Toy)
    func toyBox(_ toyBox: ToyBox, putAway toy: Toy)
}

public struct ToyDescriptor {
    let name: String?
    let identifier: UUID
    let rssi: Int?
    let advertisedPower: Int?
    
    private let disasociationLevel = 96.0
    public func signalStrength() -> Int {
        guard let rssi = rssi else { return 0 }
        
        let advertisementPowerFactor = advertisedPower == -10 ? 48.0 : 30.0
        let ratio =  1.0 / -(disasociationLevel - advertisementPowerFactor)
        var logSignalQuality = (1.0 - (disasociationLevel + Double(rssi))) * ratio
        
        if logSignalQuality > 1.0 {
            logSignalQuality = 1.0
        }
        
        return Int(logSignalQuality * 100.0)
    }
}

public final class ToyBox {
    
    class ToyBoxListenerWeakWrapper {
        weak var value: ToyBoxListener?
        
        init(value: ToyBoxListener) {
            self.value = value
        }
    }
    
    private var listeners: [ToyBoxListenerWeakWrapper] = []
    
    public func addListener(_ listener: ToyBoxListener) {
        if !listeners.contains() { $0 === listener } {
            listeners.append(ToyBoxListenerWeakWrapper(value: listener))
        }
    }
    
    public func removeListener(_ listener: ToyBoxListener) {
        guard let index = listeners.index(where: {$0 === listener }) else { return }
        listeners.remove(at: index)
    }
    
    private var queue = DispatchQueue(label: "com.sphero.sdk.queue")
    private lazy var centralManagerDelegate: ToyBoxCBCentralManagerDelegate? = { [weak self] in
        return ToyBoxCBCentralManagerDelegate(self)
        }()
    
    public lazy var centralManager: PlaygroundBluetoothCentralManager = { [weak self] in
        let centralManager = PlaygroundBluetoothCentralManager(services: [SpheroV1Services.robotControlService, SpheroV2Services.apiV2ControlService], queue: .main)
        centralManager.delegate = self?.centralManagerDelegate
        return centralManager
        }()
    
    private var connectedToys: [UUID: Toy] = [:]
    
    public init() {}
    
    @discardableResult func connectToLastConnectedPeripheral() -> Bool {
        return centralManager.connectToLastConnectedPeripheral()
    }
    
    func putAway(toy: Toy) {
        toy.putAway()
    }
    
    func disconnect(toy: Toy) {
        guard let toy = connectedToys[toy.identifier], let peripheral = toy.peripheral else { return }
        centralManager.disconnect(from: peripheral)
    }
    
    // MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: PlaygroundBluetoothCentralManager) {
        if central.state == .poweredOn {
            listeners.forEach { $0.value?.toyBoxReady(self) }
        }
    }
    
    func centralManager(_ central: PlaygroundBluetoothCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any]?, rssi: Double) {
        guard rssi < 0.0 && rssi > -70.0 else { return }
        
        let toyDescriptor = ToyDescriptor(name: peripheral.name, identifier: peripheral.identifier, rssi: Int(rssi), advertisedPower: 38)
        listeners.forEach { $0.value?.toyBox(self, discovered: toyDescriptor) }
    }
    
    func centralManager(_ central: PlaygroundBluetoothCentralManager, didConnect peripheral: CBPeripheral) {
        guard let peripheralName = peripheral.name else { fatalError("Peripheral had no name") }

        var toy: Toy?
        switch peripheralName {
        case let sprk where (sprk.hasPrefix(SPRKToy.descriptor)):
            toy = SPRKToy(peripheral: peripheral, owner: self)
            
        case let bb8 where (bb8.hasPrefix(BB8Toy.descriptor)):
            toy = BB8Toy(peripheral: peripheral, owner: self)
        
        case let bb9e where (bb9e.hasPrefix(BB9EToy.descriptor)):
            toy = BB9EToy(peripheral: peripheral, owner: self)
            
        case let r2d2 where (r2d2.hasPrefix(R2D2Toy.descriptor)):
            toy = R2D2Toy(peripheral: peripheral, owner: self)
            
        default:
            break
        }

        guard let returnToy = toy else { fatalError("Could not make toy from peripheral") }

        returnToy.connect { didPrepareConnection, error in
            if didPrepareConnection {
                self.connectedToys[peripheral.identifier] = returnToy
                self.listeners.forEach { $0.value?.toyBox(self, readied: returnToy) }
            } else {
                self.centralManager.disconnect(from: peripheral)
            }
        }
    }
    
    func centralManager(_ central: PlaygroundBluetoothCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectedToys[peripheral.identifier] = nil
    }
    
    func centralManager(_ central: PlaygroundBluetoothCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let toy = connectedToys[peripheral.identifier] else { return }
        
        connectedToys[peripheral.identifier] = nil
        
        listeners.forEach { $0.value?.toyBox(self, putAway: toy) }
    }
    
    func centralManager(_ central: PlaygroundBluetoothCentralManager, willConnectTo peripheral: CBPeripheral) {
        let toyDescriptor = ToyDescriptor(name: peripheral.name, identifier: peripheral.identifier, rssi: nil, advertisedPower: nil)
        listeners.forEach { $0.value?.toyBox(self, willReady: toyDescriptor) }
    }
    
    // Use an internal class to conform to CBCentralManagerDelegate so we're not exposing these methods.
    internal class ToyBoxCBCentralManagerDelegate: NSObject, PlaygroundBluetoothCentralManagerDelegate {
        
        weak var toyBox: ToyBox?
        
        init(_ toyBox: ToyBox?) {
            self.toyBox = toyBox
        }
        
        func centralManagerStateDidChange(_ centralManager: PlaygroundBluetoothCentralManager) {
            toyBox?.centralManagerDidUpdateState(centralManager)
        }
        
        func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didDiscover peripheral: CBPeripheral, withAdvertisementData advertisementData: [String : Any]?, rssi: Double) {
            toyBox?.centralManager(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: rssi)
        }
        
        func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, willConnectTo peripheral: CBPeripheral) {
            toyBox?.centralManager(centralManager, willConnectTo: peripheral)
        }
        
        func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didConnectTo peripheral: CBPeripheral) {
            toyBox?.centralManager(centralManager, didConnect: peripheral)
        }
        
        func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didFailToConnectTo peripheral: CBPeripheral, error: Error?) {
            toyBox?.centralManager(centralManager, didFailToConnect: peripheral, error: error)
        }
        
        func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didDisconnectFrom peripheral: CBPeripheral, error: Error?) {
            toyBox?.centralManager(centralManager, didDisconnectPeripheral: peripheral, error: error)
        }
        
    }
}
