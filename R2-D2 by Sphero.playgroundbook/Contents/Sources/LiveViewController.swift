//
//  LiveViewController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-16.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport
import PlaygroundBluetooth

@objc(LiveViewController)
public class LiveViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    class var existsInStoryboard: Bool {
        return false
    }
    
    @IBOutlet public var overlayView: UIView!
    @IBOutlet public var overlayContentView: UIView!
    
    let toyBox: ToyBox
    var toyBoxConnector: ToyBoxConnector?
    var connectedToy: AnyToy?
    var roller: RobotKeepAlive?

    let connectionHintArrowView = ConnectionHintArrowView()
    
    var aimingViewController: AimingViewController?
    var firmwareUpdateViewController: FirmwareUpdateViewController?
    
    private var topSafeAreaConstraint: NSLayoutConstraint?
    private var bottomSafeAreaConstraint: NSLayoutConstraint?
    
    fileprivate var batteryTimer: Timer?
    
    fileprivate let passSound = Sound("Bell")
    fileprivate let failSounds: [Sound] = [
        Sound("No"),
        Sound("Sad"),
        Sound("Dizzy")
    ]
    
    public var toyBoxConnectorItems: [ToyBoxConnectorItem] {
        get {
            return [
                ToyBoxConnectorItem(prefix: R2D2Toy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.r2d2", value: "R2-D2", comment: "R2-D2 robot"),
                                    icon: UIImage(named: "connection-r2d2")!)
            ]
        }
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.toyBox = ToyBox()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.toyBox = ToyBox()
        super.init(coder: aDecoder)
    }
    
    public var shouldPresentAim: Bool {
        return false
    }
    
    public lazy var boundedLiveViewSafeAreaFrame: UILayoutGuide = {
        let layoutGuide = UILayoutGuide()
        self.view.addLayoutGuide(layoutGuide)
        
        let bottomConstraint = layoutGuide.bottomAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.bottomAnchor)
        bottomConstraint.priority = 999
        
        NSLayoutConstraint.activate([
            layoutGuide.topAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.topAnchor),
            layoutGuide.leadingAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.trailingAnchor),
            bottomConstraint,
            
            // Anything larger than 139 means the keyboard is covering the live view.
            layoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: self.view.bottomAnchor, constant: -139.0)
            ])
        
        return layoutGuide
    }()
    
    public var shouldAutomaticallyConnectToToy = true
    
    var isLiveViewMessageConnectionOpened = false
    var toyConnectionView: PlaygroundBluetoothConnectionView?
    
    public override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            toyConnectionView?.removeFromSuperview()
            
            if let connectedToy = connectedToy {
                toyBox.putAway(toy: connectedToy.toy)
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        toyBox.addListener(self)
        
        PlaygroundPage.current.needsIndefiniteExecution = true
        
        // Add the connection view.
        if shouldAutomaticallyConnectToToy {
            connectToNearest()
        }
        
        // Set up the constraints for the overlay view.
        if let overlayView = overlayView {
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0),
                overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0),
                ])
        }
        
        // Set up the constraints for the overlay content view.
        if let overlayContentView = overlayContentView {
            let liveAreaSafeFrame = liveViewSafeAreaFrame
            let topConstraint = overlayContentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: liveAreaSafeFrame.minY)
            let bottomConstraint = overlayContentView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -(view.bounds.size.height - liveAreaSafeFrame.maxY))
            
            NSLayoutConstraint.activate([
                overlayContentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                bottomConstraint,
                topConstraint
                ])
            
            topSafeAreaConstraint = topConstraint
            bottomSafeAreaConstraint = bottomConstraint
        }
        
        if let toyConnectionView = toyConnectionView {
            view.insertSubview(connectionHintArrowView, belowSubview: toyConnectionView)
            connectionHintArrowView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                connectionHintArrowView.trailingAnchor.constraint(equalTo: toyConnectionView.leadingAnchor),
                connectionHintArrowView.topAnchor.constraint(equalTo: toyConnectionView.topAnchor)
                ])
        }
        
        // The way the LiveViewController detects layout changes is by overriding viewWillLayoutSubviews().
        // But that will only be called if there is some view that is constrained to the liveViewSafeAreaGuide.
        // So create a view that does that.
        let safeAreaView = UIView()
        safeAreaView.translatesAutoresizingMaskIntoConstraints = false
        safeAreaView.isUserInteractionEnabled = false
        
        view.addSubview(safeAreaView)
        
        NSLayoutConstraint.activate([
            safeAreaView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor),
            safeAreaView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor),
            safeAreaView.leadingAnchor.constraint(equalTo: liveViewSafeAreaGuide.leadingAnchor),
            safeAreaView.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor),
            ])
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //liveViewConnectionClosed doesn't get called if a user switches pages while it's running. Set stance to bipod here to make sure we don't keep waddling
        connectedToy?.setStance(.bipod)

        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        aimingViewController?.insetLayoutGuide = liveViewSafeAreaGuide
        firmwareUpdateViewController?.insetLayoutGuide = liveViewSafeAreaGuide
        
        overlayView?.isHidden = isVeryCompact()
        
        updateViewConstraints()
        view.setNeedsUpdateConstraints()
    }
    
    public override func updateViewConstraints() {
        if let topSafeConstraint = topSafeAreaConstraint, let bottomSafeConstraint = bottomSafeAreaConstraint {
            let liveAreaSafeFrame = liveViewSafeAreaFrame
            topSafeConstraint.constant = liveAreaSafeFrame.minY == 0.0 ? 40.0 : liveAreaSafeFrame.minY
            bottomSafeConstraint.constant = -(view.bounds.size.height - liveAreaSafeFrame.maxY)
            
            view.setNeedsUpdateConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    @objc private func didEnterBackground() {
        guard let connectedToy = connectedToy else { return }
        toyBox.putAway(toy: connectedToy.toy)
    }
    
    @objc private func willEnterForeground() {
        hideModalViewControllers()
    }
    
    private func heightScaleFactor() -> CGFloat {
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.size.height
        let currentWidth = liveViewSafeAreaGuide.layoutFrame.size.width
        
        let originalHeight: CGFloat
        if currentHeight > currentWidth {
            originalHeight = 1024.0
        } else {
            originalHeight = 768.0
        }
        
        return currentHeight / originalHeight
    }
    
    private func widthScaleFactor() -> CGFloat {
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.size.height
        let currentWidth = liveViewSafeAreaGuide.layoutFrame.size.width
        
        let originalWidth: CGFloat
        if currentHeight > currentWidth {
            originalWidth = 768.0
        } else {
            originalWidth = 1024.0
        }
        
        return currentWidth / originalWidth
    }
    
    public func isVeryCompact() -> Bool {
        return heightScaleFactor() < 0.40 && widthScaleFactor() < 0.40
    }
    
    public func isVerticallyCompact() -> Bool {
        return (view.bounds.size.height < 600.0)
    }
    
    public func isHorizontallyCompact() -> Bool {
        return (view.bounds.size.width < 600.0)
    }
    
    
    public var liveViewSafeAreaFrame: CGRect {
        get {
            return self.liveViewSafeAreaGuide.layoutFrame
        }
    }
    
    func createToyBoxConnector() -> ToyBoxConnector {
        return ToyBoxConnector(items: toyBoxConnectorItems)
    }
    
    func connectToNearest() {
        if toyConnectionView == nil {
            toyBoxConnector = createToyBoxConnector()
            
            toyConnectionView = PlaygroundBluetoothConnectionView(centralManager: toyBox.centralManager, delegate: toyBoxConnector, dataSource: toyBoxConnector)
            view.addSubview(toyConnectionView!)
            
            NSLayoutConstraint.activate([
                toyConnectionView!.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 20),
                toyConnectionView!.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -20)
                ])
        }
    }
    
    func playAssessmentSound(playPassSound didPass: Bool) {
        if didPass {
            passSound.play()
        } else {
            let soundIndex = Int(arc4random_uniform(UInt32(failSounds.count)))
            failSounds[soundIndex].play()
        }
    }
    
    func addModalViewController(_ viewController: ModalViewController, callback: @escaping (Bool) -> Void) {
        viewController.insetLayoutGuide = liveViewSafeAreaGuide
        if let toyConnectionView = toyConnectionView {
            view.insertSubview(viewController.view, belowSubview: toyConnectionView)
        } else {
            view.addSubview(viewController.view)
        }
        viewController.didMove(toParentViewController: self)
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0),
            ])
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, viewController.view)
        
        viewController.animateIn(callback: callback)
    }
    
    func removeModalViewController(_ viewController: ModalViewController, callback: @escaping (Bool) -> Void) {
        viewController.animateOut { (completed) in
            viewController.willMove(toParentViewController: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
            
            callback(completed)
        }
    }
    
    // TODO: refactor
    open func didReceiveRollMessage(heading: Double, speed: Double) {
        roller?.updateLastRoll(speed: speed, heading: heading)
    }
    
    open func didReceiveSetMainLedMessage(color: UIColor) { }
    open func didReceiveSetFrontPSILedMessage(color: UIColor) { }
    open func didReceiveSetBackPSILedMessage(color: UIColor) { }
    open func didReceiveSetHoloProjectorLedMesssage(brightness: Double) { }
    open func didReceiveSetLogicDiplayLedMesssage(brightness: Double) { }
    open func didReceiveSetDomePositionMessage(angle: Double) { }
    open func didReceiveSetStanceMessage(stance: StanceCommand.StanceId) { }
    open func didReceiveEnableSensorsMessage(sensors: SensorMask) { }
    open func didReceiveSetCollisionDetectionMesssage(configuration: CollisionConfiguration) { }
    open func didReceiveCollision(data: CollisionData) { }
    open func didReceiveSensorData(_ data: SensorControlData) { }
    open func toyDidFreefall() { }
    open func toyDidLand() { }
    
    open func onReceive(message: PlaygroundValue) { }
    
}

extension LiveViewController: ToyBoxListener {
    
    public func toyBoxReady(_ toyBox: ToyBox) {
        if shouldAutomaticallyConnectToToy {
            toyBox.connectToLastConnectedPeripheral()
        }
    }
    
    public func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) {
    }
    
    public func toyBox(_ toyBox: ToyBox, willReady descriptor: ToyDescriptor) {
        connectionHintArrowView.hide()
    }
    
    public func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
        guard let peripheral = toy.peripheral else { return }
        let anyToy = AnyToy(toy: toy)
        
        connectedToy = anyToy
        roller = RobotKeepAlive(toy: anyToy);

        connectionHintArrowView.hide()
        
        if requiresFirmwareUpdate(for: toy) {
            toyConnectionView?.setFirmwareStatus(.outOfDate, forPeripheral: peripheral)
            showFirmwareUpdateViewController()
            return
        }
        
        if let batteryLevel = connectedToy?.batteryLevel {
            toyConnectionView?.setBatteryLevel(batteryLevel, forPeripheral: peripheral)
        }
        
        anyToy.onCollisionDetected = { [weak self] data in
            self?.sendCollisionMessage(data: data)
            self?.didReceiveCollision(data: data)
        }
        
        anyToy.sensorControl?.onDataReady = { [weak self] data in
            self?.sendSensorDataMessage(data: data)
            self?.didReceiveSensorData(data)
        }
        
        anyToy.sensorControl?.onFreefallDetected = { [weak self] in
            self?.sendFreefallMessage()
            self?.toyDidFreefall()
        }
        
        anyToy.sensorControl?.onLandingDetected = { [weak self] in
            self?.sendLandMessage()
            self?.toyDidLand()
        }

        anyToy.onBatteryUpdated = { [weak self] batteryVoltageLevel in
            if let batteryLevel = batteryVoltageLevel, let peripheral = self?.connectedToy?.peripheral {
                self?.toyConnectionView?.setBatteryLevel(batteryLevel, forPeripheral: peripheral)
            }
        }
        
        anyToy.setAudioVolume(128)
        anyToy.setStanceChangedNotifications(enabled: true)
        
        //start up a timer to read our battery every once in a while
        if let batteryTimer = batteryTimer {
            batteryTimer.invalidate()
            self.batteryTimer = nil
        }
        
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] timer in
            self?.connectedToy?.getPowerState()
        })
        
        if isLiveViewMessageConnectionOpened {
            sendToyReadyMessage()
        }
    }
    
    public func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
        guard toy === connectedToy?.toy else { return }
        
        connectedToy = nil
        roller = nil
        
        batteryTimer?.invalidate()
        batteryTimer = nil
        
        hideModalViewControllers()
        
        sendMessageToContents(
            .dictionary([
                MessageKeys.type: MessageTypeId.didDisconnect.playgroundValue()
                ])
        )
    }
    
    func requiresFirmwareUpdate(for toy: Toy?) -> Bool {
        guard let toy = toy else { return false }
        guard let appVersion = toy.appVersion else { return false }
        switch toy {
        case is SPRKToy:
            return appVersion < AppVersion(major: "7", minor: "21")
        case is BB8Toy:
            return appVersion < AppVersion(major: "4", minor: "69")
        case is R2D2Toy:
            return appVersion < AppVersion(major: "5", minor: "0")
        case is BB9EToy:
            return appVersion < AppVersion(major: "5", minor: "0")
            
        default:
            return false
        }
    }
    
    func showAimingController() {
        guard !requiresFirmwareUpdate(for: connectedToy?.toy) else { return }
        guard aimingViewController == nil else { return }
        
        connectedToy?.startAiming()
        
        aimingViewController = AimingViewController.instantiate(with: connectedToy?.toy, callback: { [weak self] aimingViewController in
            if let connectedToy = self?.connectedToy {
                connectedToy.stopAiming()
            }
            if let aimingViewController = self?.aimingViewController {
                aimingViewController.animateOut { _ in
                    self?.removeModalViewController(aimingViewController) { (_) in
                        self?.sendToyReadyMessage()
                    }
                }
            }
        })
        
        addModalViewController(aimingViewController!) { (_) in
        }
    }
    
    func showFirmwareUpdateViewController() {
        guard firmwareUpdateViewController == nil else { return }
        
        firmwareUpdateViewController = FirmwareUpdateViewController.instantiate(with: connectedToy?.toy)

        //template has a generic blue background
        if type(of: self) == TemplateLiveViewController.self {
            firmwareUpdateViewController?.topGradientColor = nil
            firmwareUpdateViewController?.bottomGradientColor = nil
        } else {
            firmwareUpdateViewController?.topGradientColor = UIColor(colorLiteralRed: 15.0/255.0, green: 197.0/255.0, blue: 165.0/255.0, alpha: 1.0)
            firmwareUpdateViewController?.bottomGradientColor = UIColor(colorLiteralRed: 40.0/255.0, green: 159.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        }
        
        addModalViewController(firmwareUpdateViewController!) { (_) in
        }
    }
    
    func hideModalViewControllers() {
        if let aimingViewController = aimingViewController {
            removeModalViewController(aimingViewController) { (_) in
                self.aimingViewController = nil
            }
        }
        if let firmwareUpdateViewController = firmwareUpdateViewController {
            removeModalViewController(firmwareUpdateViewController) { (_) in
                self.firmwareUpdateViewController = nil
            }
        }
    }
    
}
