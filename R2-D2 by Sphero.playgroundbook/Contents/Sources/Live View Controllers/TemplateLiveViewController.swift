//
//  TemplateLiveViewController.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-04-26.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundBluetooth

@objc(TemplateLiveViewController)
public class TemplateLiveViewController: LiveViewController {
    
    @IBOutlet weak var velocitySensorView: SensorDisplayView?
    @IBOutlet weak var headingSensorView: SensorDisplayView?
    @IBOutlet weak var accelSensorView: SensorDisplayView?
    @IBOutlet weak var gyroSensorView: SensorDisplayView?
    
    @IBOutlet weak var joystickView: JoystickView?
    @IBOutlet weak var aimingView: AimingView?
    
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var controlsContainerView: UIStackView?
    
    @IBOutlet weak var aimLabel: UILabel?
    @IBOutlet weak var driveLabel: UILabel?
    
    private var bottomSensorViewConstraint: NSLayoutConstraint?

    private var bottomContentViewConstraint: NSLayoutConstraint?

    public override var shouldPresentAim: Bool {
        return false
    }
    
    public override class var existsInStoryboard: Bool {
        return true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let gyroSensorView = gyroSensorView,
            let velocitySensorView = velocitySensorView,
            let headingSensorView = headingSensorView,
            let accelSensorView = accelSensorView {
        
            let bottomSensorConstraint = gyroSensorView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: -30.0)
            NSLayoutConstraint.activate([
                bottomSensorConstraint
                ])
            bottomSensorViewConstraint = bottomSensorConstraint

            
            let velocityTitle = NSLocalizedString("template.velocitySensor.titleLabel", value: "Velocity", comment: "velocity sensor title, velocity is how fast Sphero is rolling")
            velocitySensorView.titleLabel.text = velocityTitle.uppercased()
            velocitySensorView.isAccessibilityElement = true

            let headingTitle = NSLocalizedString("template.headingSensor.titleLabel", value: "Heading", comment: "heading sensor title, heading is the direction Sphero is rolling")
            headingSensorView.titleLabel.text = headingTitle.uppercased()
            headingSensorView.isAccessibilityElement = true

            let accelTitle = NSLocalizedString("template.accelSensor.titleLabel", value: "Accelerometer", comment: "accelerometer sensor title, accelerometer is how fast Sphero is accelerating")
            accelSensorView.titleLabel.text = accelTitle.uppercased()
            accelSensorView.isAccessibilityElement = true
            
            let gyroTitle = NSLocalizedString("template.gyroSensor.titleLabel", value: "Gyroscope", comment: "gyro sensor title, gyroscope is have fast Sphero is spinning")
            gyroSensorView.titleLabel.text = gyroTitle.uppercased()
            gyroSensorView.isAccessibilityElement = true
            
            updateVelocitySensor(value: 0.0)
            updateHeadingSensor(value: 0.0)
            updateAccelSensor(value: 0.0)
            updateGyroSensor(value: 0.0)
        }
        
        if let joystickView = joystickView,
            let aimingView = aimingView,
            let _ = controlsContainerView {
        
            joystickView.onChange = { [weak self] (x: Double, y: Double) in
                self?.sendMessageToContents(.dictionary([
                    MessageKeys.type: MessageTypeId.joystick.playgroundValue(),
                    MessageKeys.x: .floatingPoint(x),
                    MessageKeys.y: .floatingPoint(y)
                ]))
            }
            
            aimingView.onStartAiming = { [weak self] in
                guard let `self` = self else { return }
                
                self.joystickView?.disable()
            
                self.sendMessageToContents(.dictionary([
                    MessageKeys.type: MessageTypeId.aimControlStart.playgroundValue()
                ]))
            }
            
            aimingView.onFinishAiming = { [weak self] in
                guard let `self` = self else { return }
                
                if self.isLiveViewMessageConnectionOpened {
                    self.joystickView?.enable()
                }
                
                self.sendMessageToContents(.dictionary([
                    MessageKeys.type: MessageTypeId.aimControlStop.playgroundValue()
                ]))
            }
            
            aimingView.onHeadingChanged = { [weak self] (heading: Int) in
                self?.sendMessageToContents(.dictionary([
                    MessageKeys.type: MessageTypeId.aimControlHeading.playgroundValue(),
                    MessageKeys.heading: .integer(heading)
                ]))
            }
        }
        
        if let contentView = contentView {
            bottomContentViewConstraint = contentView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor)
        
            NSLayoutConstraint.activate([
                contentView.leadingAnchor.constraint(equalTo: liveViewSafeAreaGuide.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor),
                contentView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 70.0),
                bottomContentViewConstraint!
            ])
        }
        
        driveLabel?.text = NSLocalizedString("templateLiveViewController.drive.heading", value: "Drive", comment: "Header above a joystick used to drive around a toy.")
        
        aimLabel?.text = NSLocalizedString("templateLiveViewController.aim.heading", value: "Aim", comment: "Header above an aiming control used to turn a toy around.")
    }
    
    public override var toyBoxConnectorItems: [ToyBoxConnectorItem] {
        get {
            return [
                ToyBoxConnectorItem(prefix: SPRKToy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.sprk", value: "SPRK+", comment: "SPRK+ robot"),
                                    icon: UIImage(named: "connection-sphero")!),
                ToyBoxConnectorItem(prefix: BB8Toy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.bb8", value: "BB-8", comment: "BB-8 robot"),
                                    icon: UIImage(named: "connection-bb8")!),
                ToyBoxConnectorItem(prefix: R2D2Toy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.r2d2", value: "R2-D2", comment: "R2-D2 robot"),
                                    icon: UIImage(named: "connection-r2d2")!),
                ToyBoxConnectorItem(prefix: BB9EToy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.bb9e", value: "BB-9E", comment: "BB-9E robot"),
                                    icon: UIImage(named: "connection-bb9e")!)
            ]
        }
    }
    
    override func createToyBoxConnector() -> ToyBoxConnector {
        let connector = super.createToyBoxConnector()
        connector.titleForState = { (state: PlaygroundBluetoothConnectionView.State) in
    
            switch state {
            case .noConnection:
                return NSLocalizedString("template.connection.view.noConnection", value: "Connect Robot", comment: "Connection view state -- not connected")
            case .connecting:
                return NSLocalizedString("template.connection.view.connecting", value: "Connecting Robot", comment: "Connection view state -- connecting")
            case .searchingForPeripherals:
                return NSLocalizedString("template.connection.view.searching", value: "Searching for Robots", comment: "Connection view state -- searching for robots")
            case .selectingPeripherals:
                return NSLocalizedString("template.connection.view.selecting", value: "Select a Robot", comment: "Connection view state -- selecting a robot")
            case .connectedPeripheralFirmwareOutOfDate:
                return NSLocalizedString("template.connection.view.firmwareoutofdate", value: "Connect to a Different Robot", comment: "Connection view state -- Robot cannot be used")
            }
        }
        
        return connector
    }
    
    public override func didReceiveSensorData(_ data: SensorControlData) {
        super.didReceiveSensorData(data)
        
        if let velocityX = data.locator?.velocity?.x, let velocityY = data.locator?.velocity?.y {
            updateVelocitySensor(value: hypot(velocityX, velocityY))
        }
        if let accelX = data.accelerometer?.filteredAcceleration?.x, let accelY = data.accelerometer?.filteredAcceleration?.y, let accelZ = data.accelerometer?.filteredAcceleration?.z {
            updateAccelSensor(value: sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ))
        }
        if let gyroX = data.gyro?.rotationRate?.x, let gyroY = data.gyro?.rotationRate?.y, let gyroZ = data.gyro?.rotationRate?.z {
            updateGyroSensor(value: sqrt(Double(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ)) / 10.0)
        }
    }
    
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        super.didReceiveRollMessage(heading: heading, speed: speed)
        
        updateHeadingSensor(value: heading)
    }
    
    private func updateHeadingSensor(value: Double) {
        headingSensorView?.accessibilityLabel = String(format: NSLocalizedString("template.headingSensor.accessibilityLabel", value: "Heading. %0.f degrees", comment: "accessibility for heading sensor view. %.0f is the direction the robot is heading in degrees. ie 130 degrees"), value)
        headingSensorView?.sensorValueLabel.text = String(format: NSLocalizedString("template.headingSensor.sensorValue.text", value: "%.0f°", comment: "value of heading sensor readout, %.0f is the robots heading in degrees, ° is the symbol for degrees."), value)
    }
    
    private func updateVelocitySensor(value: Double) {
        velocitySensorView?.accessibilityLabel = String(format: NSLocalizedString("template.velocitySensor.accessibilityLabel", value: "Velocity. %.1f centimeters per second", comment: "accessibility for velocity sensor view. %.1f is the robots speed in centimeters per second, ie 13 cm/s"), value)
        velocitySensorView?.sensorValueLabel.text = String(format: NSLocalizedString("template.velocitySesnor.sensorValue.text", value: "%.1f cm/s", comment: "value of the velocity sensor readout, %.1f is the robots speed in centimeters per second, ie 13 cm/s"), value)
    }
    
    private func updateAccelSensor(value: Double) {
        accelSensorView?.accessibilityLabel = String(format: NSLocalizedString("template.accelSensor.accessibilityLabel", value: "Accelerometer. %.1f g-forces", comment: "accessibility for accelerometer sensor view. %.0f is the acceleration the robot in g's. ie 1.4 g's"), value)
        accelSensorView?.sensorValueLabel.text = String(format: NSLocalizedString("template.accelSensor.sensorValue.text", value: "%.1f g", comment: "value of accelerometer sensor readout, %.1f is the robots acceleration in g's. ie 1.4 g's"), value)
    }
    
    private func updateGyroSensor(value: Double) {
        gyroSensorView?.accessibilityLabel = String(format: NSLocalizedString("template.gyroSensor.accessibilityLabel", value: "Gyroscope. %0.f degrees per second", comment: "accessibility for gyro sensor view. %.0f is the robots rate of rotation in degrees per second, ie 500 °/s"), value)
        gyroSensorView?.sensorValueLabel.text = String(format: NSLocalizedString("template.gyroSensor.sensorValue.text", value: "%.0f °/s", comment: "value of the gyro sensor readout, %.0f is the robots rate of rotation in degrees per second, ie 500 °/s"), value)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let pillWidth: CGFloat = isVeryCompact() ? 75.0 : 150.0
       
        velocitySensorView?.minimumPillWidth = pillWidth
        headingSensorView?.minimumPillWidth = pillWidth
        accelSensorView?.minimumPillWidth = pillWidth
        gyroSensorView?.minimumPillWidth = pillWidth

        if let velocitySensorView = velocitySensorView, velocitySensorView.minimumPillWidth != pillWidth {
            view.setNeedsLayout()
        }
    }
    
    public override func updateViewConstraints() {
        if isVeryCompact() {
            bottomSensorViewConstraint?.constant = 0.0
        } else {
            bottomSensorViewConstraint?.constant = -30.0
        }
        
        super.updateViewConstraints()
    }
    
    public override func liveViewMessageConnectionClosed() {
        super.liveViewMessageConnectionClosed()
        
        joystickView?.disable()
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
    
        joystickView?.enable()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    
        self.controlsContainerView?.axis = view.bounds.size.width > view.bounds.size.height ? .horizontal : .vertical
        self.controlsContainerView?.spacing = isVeryCompact() ? 0.0 : (isHorizontallyCompact() ? 20.0 : 60.0)
        
        bottomContentViewConstraint?.constant = isVeryCompact() ? 0.0 : -40.0
    }
    
}

@objc(TemplateDrivingLiveViewController)
public class TemplateDrivingLiveViewController: TemplateLiveViewController { }
