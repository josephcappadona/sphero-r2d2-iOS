//
//  ViewController.swift
//  R2D2
//
//  Created by Joseph Cappadona on 5/16/19.
//  Copyright © 2019 Joseph Cappadona. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    let cellReuseIdentifier = "AvailableConnectionCell"
    @IBOutlet weak var availableConnectionsTableView: UITableView!
    @IBOutlet weak var discoveryButton: UIButton!
    
    var discoveredDescriptors: Set<ToyDescriptor> = Set<ToyDescriptor>()
    var discoveredDescriptorsByRSSI: [ToyDescriptor] = []
    var descriptorToRSSI: [ToyDescriptor : Int] = [:]
    var isDiscovering = false
    
    var toyBox: ToyBox? = nil
    var connectedToy: Toy? = nil
    var connectedAnyToy: AnyToy? = nil
    var connectedToyDescriptor: ToyDescriptor? = nil
    var readyingToyDescriptor: ToyDescriptor? = nil
    var roller: RobotKeepAlive? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToybox()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (connectedToy != nil) {
            connectedToy = nil
            connectedAnyToy = nil
            connectedToyDescriptor = nil
            readyingToyDescriptor = nil
            roller = nil
        }
    }
    
    func setupToybox() {
        toyBox = ToyBox()
        toyBox?.addListener(self)
    }
    
    func startScanning() {
        isDiscovering = true
        toyBox?.startScanning()
        discoveryButton.setTitle("Stop Discovery", for: .normal)
    }
    
    func stopScanning() {
        isDiscovering = false
        toyBox?.stopScanning()
        discoveryButton.setTitle("Start Discovery", for: .normal)
    }
    
    func connect(descriptor: ToyDescriptor) {
        toyBox?.connect(descriptor: descriptor)
    }
    
    func disconnect(descriptor: ToyDescriptor) {
        toyBox?.disconnect(descriptor: descriptor)
    }
    
    @IBAction func discoveryButtonPressed(_ sender: Any) {
        if (!isDiscovering) {
            startScanning()
        } else {
            stopScanning()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowConnectedViewController") {
            let destination = segue.destination as! ConnectedViewController
            destination.delegate = self
            destination.toyBox = toyBox
            //destination.toy = connectedToy
            //destination.anyToy = connectedAnyToy
            destination.descriptor = readyingToyDescriptor
            //destination.roller = roller
        }
    }
}

extension ViewController: ToyBoxListener {
    public func toyBoxReady(_ toyBox: ToyBox) {
        print("toybox ready")
    }
    
    public func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) {
        //print("discovered droid: \(descriptor.name!)   \(descriptor.rssi!)")
        discoveredDescriptors.remove(descriptor)
        discoveredDescriptors.insert(descriptor)
        descriptorToRSSI[descriptor] = descriptor.rssi!
        availableConnectionsTableView.reloadData()
        discoveredDescriptorsByRSSI = discoveredDescriptors.sorted(by: { $0.rssi! > $1.rssi! })
    }
    
    public func toyBox(_ toyBox: ToyBox, willReady descriptor: ToyDescriptor) {
    }
    
    public func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
        /*
        print("readied toy")
        guard let peripheral = toy.peripheral else { return }
        let anyToy = AnyToy(toy: toy)
        
        connectedToy = toy
        connectedToyDescriptor = readyingToyDescriptor
        roller = RobotKeepAlive(toy: anyToy)
        
        if let batteryLevel = connectedToy?.batteryLevel {
            //toyConnectionView?.setBatteryLevel(batteryLevel, forPeripheral: peripheral)
            print("battery level: \(batteryLevel)")
        }
        
        toy.setToyOptions([.EnableMotionTimeout])
        
        if toy is BoltToy {
            anyToy.setFrontLed(color: .black)
            anyToy.setBackLed(color: .black)
            anyToy.setMatrix(rotation: .deg0)
        }
        
        anyToy.setMainLed(color: UIColor(red: 0.0/255.0, green: 133.0/255.0, blue: 202.0/255.0, alpha: 1.0))
        
        anyToy.onCollisionDetected = { [weak self] data in
            //self?.sendCollisionMessage(data: data)
            //self?.didReceiveCollision(data: data)
        }
        
        anyToy.sensorControl?.onDataReady = { [weak self] data in
            //self?.sendSensorDataMessage(data: data)
            //self?.didReceiveSensorData(data)
        }
        
        anyToy.sensorControl?.onFreefallDetected = { [weak self] in
            //self?.sendFreefallMessage()
            //self?.toyDidFreefall()
        }
        
        anyToy.sensorControl?.onLandingDetected = { [weak self] in
            //self?.sendLandMessage()
            //self?.toyDidLand()
        }
        
        anyToy.onBatteryUpdated = { [weak self] batteryVoltageLevel in
            if let batteryLevel = batteryVoltageLevel, let peripheral = self?.connectedToy?.peripheral {
                //self?.toyConnectionView?.setBatteryLevel(batteryLevel, forPeripheral: peripheral)
            }
        }
        
        if toy is R2D2Toy {
            anyToy.setAudioVolume(128)
            anyToy.setStanceChangedNotifications(enabled: true)
            //anyToy.setStance(.tripod)
            //anyToy.setStance(.bipod)
        }
        
        //start up a timer to read our battery every once in a while
        /*if let batteryTimer = batteryTimer {
            batteryTimer.invalidate()
            self.batteryTimer = nil
        }
        
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] timer in
            self?.connectedToy?.getPowerState()
        })
        
        if isLiveViewMessageConnectionOpened {
            sendToyReadyMessage()
        }*/
        performSegue(withIdentifier: "ShowConnectedViewController", sender: self)
        */
    }
    
    public func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
        print("put away toy")
        guard toy === connectedAnyToy?.toy else { return }
        
        connectedToy = nil
        roller = nil
        
        //batteryTimer?.invalidate()
        //batteryTimer = nil
        
        //hideModalViewControllers()
        
        /*sendMessageToContents(
            .dictionary([
                MessageKeys.type: MessageTypeId.didDisconnect.playgroundValue()
                ])
        )*/
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDescriptorsByRSSI.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! AvailableConnectionTableViewCell
        let descriptor = discoveredDescriptorsByRSSI[indexPath.row]
        cell.nameLabel.text = descriptor.name
        cell.uuidLabel.text = descriptor.identifier.uuidString
        cell.rssiLabel.text = String(descriptor.rssi!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stopScanning()
        let descriptor = discoveredDescriptorsByRSSI[indexPath.row]
        readyingToyDescriptor = descriptor
        performSegue(withIdentifier: "ShowConnectedViewController", sender: self)
        //connect(descriptor: descriptor)
    }
}

class AvailableConnectionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
