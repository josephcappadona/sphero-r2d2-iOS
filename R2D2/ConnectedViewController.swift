//
//  ConnectedViewController.swift
//  R2D2
//
//  Created by Joseph Cappadona on 6/7/19.
//  Copyright © 2019 Joseph Cappadona. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConnectedViewController: UIViewController {
    
    var delegate: ViewController?

    var toyBox: ToyBox?
    var toy: Toy?
    var anyToy: AnyToy?
    var roller: RobotKeepAlive?
    var descriptor: ToyDescriptor?
    
    var stance = StanceCommand.StanceId.bipod
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toyBox?.addListener(self)
        toyBox?.connect(descriptor: descriptor!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toy?.peripheral?.delegate = self
        nameLabel.text = descriptor!.name
        uuidLabel.text = descriptor!.identifier.uuidString
        rssiLabel.text = String((descriptor?.rssi)!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        delegate?.disconnect(descriptor: descriptor!)
    }
    
    @IBAction func changeStanceButtonPressed(_ sender: Any) {
        /*if toy is R2D2Toy {
            if (stance == .bipod) {
                anyToy?.setStance(.tripod)
                stance = .tripod
            } else {
                anyToy?.setStance(.bipod)
                stance = .bipod
            }
        }*/
        print(toy?.identifier.uuidString)
        if toy is R2D2Toy {
            print("button")
            anyToy?.setStance(.bipod)
            
        }
    }
    
    @IBAction func speakButtonPressed(_ sender: Any) {
        anyToy?.playSound(.hello, playbackMode: .afterCurrent)
    }
    
}

extension ConnectedViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        rssiLabel.text = RSSI.stringValue
    }
}


extension ConnectedViewController: ToyBoxListener {
    public func toyBoxReady(_ toyBox: ToyBox) { }
    
    public func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) { }
    
    public func toyBox(_ toyBox: ToyBox, willReady descriptor: ToyDescriptor) { }
    
    public func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
        print("readied toy")
        guard let peripheral = toy.peripheral else { return }
        let anyToy = AnyToy(toy: toy)
        
        self.toy = toy
        roller = RobotKeepAlive(toy: anyToy)
        
        if let batteryLevel = self.toy?.batteryLevel {
            //toyConnectionView?.setBatteryLevel(batteryLevel, forPeripheral: peripheral)
            print("battery level: \(batteryLevel)")
        }
        
        //toy.setToyOptions([.EnableMotionTimeout])
        
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
            if let batteryLevel = batteryVoltageLevel, let peripheral = self?.toy?.peripheral {
                //self?.toyConnectionView?.setBatteryLevel(batteryLevel, forPeripheral: peripheral)
            }
        }
        
        if toy is R2D2Toy {
            anyToy.setAudioVolume(128)
            anyToy.setStanceChangedNotifications(enabled: true)
            anyToy.playSound(.hello, playbackMode: .immediately)
            toy.putAway()
            //anyToy.
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
    }
    
    public func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
        print("put away toy")
        guard toy === anyToy?.toy else { return }
        
        self.toy = nil
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
