//
//  ToyBox.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-08.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

struct SpheroDescription {
    let name: String?
    let identifier: UUID
    let rssi: Int
}

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

public struct ToyDescriptor: Hashable {
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
    
    public static func ==(left: ToyDescriptor, right: ToyDescriptor) -> Bool {
        return left.identifier == right.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(identifier.uuidString)
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
        guard let index = listeners.firstIndex(where: {$0 === listener }) else { return }
        listeners.remove(at: index)
    }
    
    private var queue = DispatchQueue(label: "com.sphero.sdk.queue")
    private lazy var centralManagerDelegate: ToyBoxCBCentralManagerDelegate? = { [weak self] in
        return ToyBoxCBCentralManagerDelegate(self)
        }()
    
    public lazy var centralManager: CBCentralManager = { [weak self] in
        let options = [CBCentralManagerOptionShowPowerAlertKey: true]
        let centralManager = CBCentralManager(delegate: nil, queue: .main, options: options)
        return centralManager
        }()
    
    public func startScanning() {
        if (!centralManager.isScanning) {
            print("start scanning")
            centralManager.scanForPeripherals(withServices: [SpheroV2Services.apiV2ControlService], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            print("is scanning: \(centralManager.isScanning)")
        }
    }
    
    public func stopScanning() {
        if (centralManager.isScanning) {
            print("stop scanning")
            centralManager.stopScan()
            print("is scanning: \(centralManager.isScanning)")
        }
    }
    
    public func connect(descriptor: ToyDescriptor) {
        print("connecting...")
        centralManager.connect(availablePeripherals[descriptor]!, options: nil)
    }
    
    public func disconnect(descriptor: ToyDescriptor) {
        print("disconnecting...")
        centralManager.cancelPeripheralConnection(availablePeripherals[descriptor]!)
    }
    
    public var connectedToys: [UUID: Toy] = [:]
    
    public init() {
        centralManager.delegate = centralManagerDelegate
    }
    
    func putAway(toy: Toy) {
        toy.putAway()
    }
    
    func disconnect(toy: Toy) {
        guard let toy = connectedToys[toy.identifier], let peripheral = toy.peripheral else { return }
        print("disconnecting")
        centralManager.cancelPeripheralConnection(peripheral)
        
    }
    
    // MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            listeners.forEach { $0.value?.toyBoxReady(self) }
        }
        
        switch central.state {
        case .resetting:
            print("BLE resetting")
        case .poweredOn:
            print("BLE poweredOn")
        case .poweredOff:
            print("BLE poweredOff")
        case .unauthorized:
            print("BLE unauthorized")
        case .unsupported:
            print("BLE unsupported")
        case .unknown:
            print("BLE unknown")
        default: break
        }
    }
    
    private var availablePeripherals: [ToyDescriptor : CBPeripheral] = [:]
    
    func centralManager_(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any]?, rssi: Double) {
        guard rssi < 0.0 && rssi > -90.0 else { return }
        let toyDescriptor = ToyDescriptor(name: peripheral.name, identifier: peripheral.identifier, rssi: Int(rssi), advertisedPower: 38)
        availablePeripherals[toyDescriptor] = peripheral
        listeners.forEach { $0.value?.toyBox(self, discovered: toyDescriptor) }
    }
    
    func centralManager_(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let peripheralName = peripheral.name else { fatalError("Peripheral had no name") }

        var toy: Toy?
        switch peripheralName {
        case let sprk where (sprk.hasPrefix(SPRKToy.descriptor)):
            toy = SPRKToy(peripheral: peripheral, owner: self)
        case let mini where (mini.hasPrefix(MiniToy.descriptor)):
            toy = MiniToy(peripheral: peripheral, owner: self)
        case let bolt where (bolt.hasPrefix(BoltToy.descriptor)):
            toy = BoltToy(peripheral: peripheral, owner: self, commandSequencer: CommandSequencerV21())
        case let bb8 where (bb8.hasPrefix(BB8Toy.descriptor)):
            toy = BB8Toy(peripheral: peripheral, owner: self)
        
        case let bb9e where (bb9e.hasPrefix(BB9EToy.descriptor)):
            toy = BB9EToy(peripheral: peripheral, owner: self)
            
        case let r2d2 where (r2d2.hasPrefix(R2D2Toy.descriptor)):
            toy = R2D2Toy(peripheral: peripheral, owner: self)
        
        case let r2q5 where (r2q5.hasPrefix("Q5-")):
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
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func centralManager_(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectedToys[peripheral.identifier] = nil
    }
    
    func centralManager_(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let toy = connectedToys[peripheral.identifier] else { return }
        
        connectedToys[peripheral.identifier] = nil
        
        listeners.forEach { $0.value?.toyBox(self, putAway: toy) }
    }
    
    func centralManager_(_ central: CBCentralManager, willConnectTo peripheral: CBPeripheral) {
        let toyDescriptor = ToyDescriptor(name: peripheral.name, identifier: peripheral.identifier, rssi: nil, advertisedPower: nil)
        listeners.forEach { $0.value?.toyBox(self, willReady: toyDescriptor) }
    }
    
    // Use an internal class to conform to CBCentralManagerDelegate so we're not exposing these methods.
    internal class ToyBoxCBCentralManagerDelegate: NSObject, CBCentralManagerDelegate {
        
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            toyBox?.centralManagerDidUpdateState(central)
        }
        
        
        weak var toyBox: ToyBox?
        
        init(_ toyBox: ToyBox?) {
            self.toyBox = toyBox
        }
        
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            toyBox?.centralManager_(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: Double(truncating: RSSI))
        }
        
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("did connect")
            toyBox?.centralManager_(central, didConnect: peripheral)
        }
        
        func centralManager(_ centralManager: CBCentralManager, willConnectTo peripheral: CBPeripheral) {
            print("will connect")
            toyBox?.centralManager_(centralManager, willConnectTo: peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            print("did fail to connect")
            toyBox?.centralManager_(central, didFailToConnect: peripheral, error: error)
        }
        
        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            print("did disconnect")
            toyBox?.centralManager_(central, didDisconnectPeripheral: peripheral, error: error)
        }
    }
}
