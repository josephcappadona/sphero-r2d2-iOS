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
    var toyID: Int?
    
    var stance = StanceCommand.StanceId.bipod
    var heading: Int = 0
    var headingOffset: Int = 0
    var latestOrientationData: AttitudeSensorData? = nil
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var connectingLabel: UILabel!
    
    @IBOutlet weak var stanceButton: UIButton!
    @IBOutlet weak var speakButton: UIButton!
    @IBOutlet weak var resetOrientationButton: UIButton!
    
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var cwButton: UIButton!
    @IBOutlet weak var ccwButton: UIButton!

    
    @IBOutlet weak var yawLabel: UILabel!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!
    
    @IBOutlet weak var a_xLabel: UILabel!
    @IBOutlet weak var a_yLabel: UILabel!
    @IBOutlet weak var a_zLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toyBox?.addListener(self)
        initLabels()
        disableButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toy?.peripheral?.delegate = self
        toyBox?.connect(descriptor: descriptor!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        anyToy?.setStance(.bipod)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.delegate?.disconnect(descriptor: self.descriptor!)
            self.toyBox?.removeListener(self)
        })
    }
    
    func initLabels() {
        nameLabel.text = ""
        uuidLabel.text = ""
        rssiLabel.text = ""
        batteryLabel.text = ""
        connectingLabel.text = "Connecting"
        //labelShowdata.transform = CGAffineTransformMakeScale(-1, 1)
        ccwButton.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        yawLabel.text = "?"
        rollLabel.text = "?"
        pitchLabel.text = "?"
        a_xLabel.text = "?"
        a_yLabel.text = "?"
        a_zLabel.text = "?"
    }
    
    func setupLabels() {
        nameLabel.text = descriptor!.name
        uuidLabel.text = descriptor!.identifier.uuidString
        rssiLabel.text = String((descriptor?.rssi)!)
    }
    
    func disableButtons() {
        stanceButton.setTitleColor(.darkGray, for: .normal)
        stanceButton.isUserInteractionEnabled = false
        speakButton.setTitleColor(.darkGray, for: .normal)
        speakButton.isUserInteractionEnabled = false
        resetOrientationButton.setTitleColor(.darkGray, for: .normal)
        resetOrientationButton.isUserInteractionEnabled = false
        
        forwardButton.isUserInteractionEnabled = false
        backwardButton.isUserInteractionEnabled = false
        leftButton.isUserInteractionEnabled = false
        rightButton.isUserInteractionEnabled = false
        cwButton.isUserInteractionEnabled = false
        ccwButton.isUserInteractionEnabled = false
    }
    
    func enableButtons() {
        stanceButton.setTitleColor(.blue, for: .normal)
        stanceButton.isUserInteractionEnabled = true
        speakButton.setTitleColor(.blue, for: .normal)
        speakButton.isUserInteractionEnabled = true
        resetOrientationButton.setTitleColor(.blue, for: .normal)
        resetOrientationButton.isUserInteractionEnabled = true
        
        forwardButton.isUserInteractionEnabled = true
        backwardButton.isUserInteractionEnabled = true
        leftButton.isUserInteractionEnabled = true
        rightButton.isUserInteractionEnabled = true
        cwButton.isUserInteractionEnabled = true
        ccwButton.isUserInteractionEnabled = true
    }
    
    func connecting() {
        connectingLabel.text = "Connecting"
    }
    
    func connected() {
        enableButtons()
        setupLabels()
        
        delegate?.appDelegate?.connectedToys.append(toy!)
        toyID = delegate!.appDelegate!.connectedToys.count-1
        
        if toy is R2D2Toy {
            (toy as! R2D2Toy).sensorControl.enable(sensors: [.orientation, .accelerometer])
        }
        connectingLabel.text = "Connected"
    }
    
    func disconnected() {
        connectingLabel.text = "Disconnected"
        delegate?.appDelegate?.connectedToys.remove(at: toyID!)
        toyID = nil
        toy = nil
        anyToy = nil
        roller = nil
        descriptor = nil
    }
    
    func setBatteryLevel(_ batteryVoltageLevel: Double?) {
        if let batteryLevel = batteryVoltageLevel {
            self.batteryLabel.text = "\(String(format: "%.1f", batteryLevel))V"
            //self?.batteryLabel.text = "\(Int(100*(batteryLevel/5.0)))%"
        }
    }
    
    @IBAction func changeStanceButtonPressed(_ sender: Any) {
        changeStance()
    }
    
    @IBAction func speakButtonPressed(_ sender: Any) {
        playScanSound()
    }
    
    @IBAction func resetOrientationButtonPressed(_ sender: Any) {
        resetOrientation()
    }
    
    func resetOrientation() {
        headingOffset = -((latestOrientationData?.yaw ?? 0) - 0) % 360
        print("\n\nold heading: \(heading)")
        print("headingOffset: \(headingOffset)")
        heading = 0
        print("new heading: \(heading)")
    }
    
    @IBAction func cwButtonTouchDown(_ sender: Any) {
        heading  = (heading + 45) % 360
        anyToy?.rotateAim(Double(heading + headingOffset))
    }
    
    @IBAction func ccwButtonTouchDown(_ sender: Any) {
        heading  = (heading - 45) % 360
        anyToy?.rotateAim(Double(heading + headingOffset))
    }
    
    @IBAction func forwardButtonTouchDown(_ sender: Any) {
        drive(relativeHeading: 0, speed: 100)
        forwardDriveTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkForwardDrive), userInfo: nil, repeats: true)
    }
    var forwardDriveTimer: Timer?
    @objc func checkForwardDrive() {
        if !forwardButton.isTouchInside {
            stop(relativeHeading: 0)
            forwardDriveTimer?.invalidate()
        }
    }
    
    @IBAction func backwardButtonTouchDown(_ sender: Any) {
        drive(relativeHeading: 180, speed: 100)
        backwardDriveTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkBackwardDrive), userInfo: nil, repeats: true)
    }
    var backwardDriveTimer: Timer?
    @objc func checkBackwardDrive() {
        if !backwardButton.isTouchInside {
            stop(relativeHeading: 180)
            backwardDriveTimer?.invalidate()
        }
    }
    
    @IBAction func leftButtonTouchDown(_ sender: Any) {
        drive(relativeHeading: -90, speed: 100)
        leftDriveTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkLeftDrive), userInfo: nil, repeats: true)
    }
    var leftDriveTimer: Timer?
    @objc func checkLeftDrive() {
        if !leftButton.isTouchInside {
            stop(relativeHeading: -90)
            leftDriveTimer?.invalidate()
        }
    }

    @IBAction func rightButtonTouchDown(_ sender: Any) {
        drive(relativeHeading: 90, speed: 100)
        rightDriveTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkRightDrive), userInfo: nil, repeats: true)
    }
    var rightDriveTimer: Timer?
    @objc func checkRightDrive() {
        if !rightButton.isTouchInside {
            stop(relativeHeading: 90)
            rightDriveTimer?.invalidate()
        }
    }

    @IBAction func resetButtonTouchDown(_ sender: Any) {
        stop(relativeHeading: 0)
    }
    
    func drive(relativeHeading: Int, speed: Int) {
        print("\n\nheading: \(heading)")
        print("headingOffset: \(headingOffset)")
        print("relativeHeading: \(relativeHeading)")
        let dir = (heading + headingOffset + relativeHeading) % 360
        print("dir: \(dir)")
        anyToy?.roll(heading: Double(dir), speed: Double(speed), rollType: .roll, direction: .forward)
    }
    
    func stop(relativeHeading: Int) {
        let dir = (heading + headingOffset + relativeHeading) % 360
        anyToy?.stopRoll(heading: Double(dir))
    }
}

extension ConnectedViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        receiveRSSIUpdate(RSSI: RSSI)
    }
}

extension ConnectedViewController {
    func changeStance() {
        if (stance == .bipod) {
            anyToy?.setStance(.tripod)
            stance = .tripod
            print("stance changed: tripod")
        } else {
            anyToy?.setStance(.bipod)
            stance = .bipod
            print("stance changed: bipod")
        }
    }
    
    func playScanSound() {
        anyToy?.playSound(.scan, playbackMode: .afterCurrent)
        stance = .bipod
    }
}

// SENSOR CALLBACKS
extension ConnectedViewController {
    
    func receiveRSSIUpdate(RSSI: NSNumber) {
        rssiLabel.text = RSSI.stringValue
        print("\rssi: \(RSSI.stringValue)")
    }
    
    func receiveCollisionData(_ data: CollisionData) {
        print("Collision detected")
    }
    
    func receiveSensorData(_ data: SensorControlData) {
        //print("\nSensor data ready:")
        if let accelerometer = data.accelerometer {
            receiveAccelerometerData(data: accelerometer)
        }
        if let gyro = data.gyro {
            print("\tgyro: \(gyro)")
        }
        if let locator = data.locator {
            print("\tlocator: \(locator)")
        }
        if let orientation = data.orientation {
            receiveOrientationData(data: orientation)
        }
        if let rotationMatrix = data.rotationMatrix {
            //print("\trotationMatrix: \(rotationMatrix)")
        }
        if let verticalAcceleration = data.verticalAcceleration {
            //print("\tverticalAcceleration: \(verticalAcceleration)")
        }
    }
    
    func receiveAccelerometerData(data: AccelerometerSensorData) {
        if let a_x = data.filteredAcceleration?.x {
            a_xLabel.text = String(format: "%.2f", a_x)
        }
        if let a_y = data.filteredAcceleration?.y {
            a_yLabel.text = String(format: "%.2f", a_y)
        }
        if let a_z = data.filteredAcceleration?.z {
            a_zLabel.text = String(format: "%.2f", a_z)
        }
    }
    
    func receiveOrientationData(data: AttitudeSensorData) {
        if (latestOrientationData == nil) {
            latestOrientationData = data
            resetOrientation()
        }
        latestOrientationData = data
        if let yaw = data.yaw {
            yawLabel.text = String(yaw)
        }
        if let roll = data.roll {
            rollLabel.text = String(roll)
        }
        if let pitch = data.pitch {
            pitchLabel.text = String(pitch)
        }
    }
    
    func receiveFreeFallDetection() {
        print("Free fall detected")
    }
    
    func receiveLandingDetection() {
        print("Landing detected")
    }
}


extension ConnectedViewController: ToyBoxListener {
    public func toyBoxReady(_ toyBox: ToyBox) { }
    
    public func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) { }
    
    public func toyBox(_ toyBox: ToyBox, willReady descriptor: ToyDescriptor) {
        
    }
    
    public func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
        print("readied toy")
        guard let peripheral = toy.peripheral else { return }
        let anyToy = AnyToy(toy: toy)
        
        self.toy = toy
        self.anyToy = anyToy
        roller = RobotKeepAlive(toy: anyToy)
        
        setBatteryLevel(self.toy?.batteryLevel)
        
        anyToy.setMainLed(color: UIColor(red: 0.0/255.0, green: 133.0/255.0, blue: 202.0/255.0, alpha: 1.0))
        anyToy.onCollisionDetected = { [weak self] data in
            self?.receiveCollisionData(data)
        }
        anyToy.sensorControl?.onDataReady = { [weak self] data in
            self?.receiveSensorData(data)
        }
        
        anyToy.sensorControl?.onFreefallDetected = { [weak self] in
            self?.receiveFreeFallDetection()
        }
        
        anyToy.sensorControl?.onLandingDetected = { [weak self] in
            self?.receiveLandingDetection()
        }
        
        anyToy.onBatteryUpdated = { [weak self] batteryVoltageLevel in
            self?.setBatteryLevel(batteryVoltageLevel)
        }
        
        anyToy.setAudioVolume(128)
        anyToy.setStanceChangedNotifications(enabled: true)
        anyToy.setStance(.tripod)
        
        connected()
    }
    
    public func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
        print("put away toy")
        
        guard toy === anyToy?.toy else { return }
        
        disconnected()
    }
}
