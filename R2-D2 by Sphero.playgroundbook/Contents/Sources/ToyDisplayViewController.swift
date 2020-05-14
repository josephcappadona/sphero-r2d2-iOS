//
//  ToyDisplayViewController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-09.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit
import PlaygroundSupport

@objc(ToyDisplayViewController)
public class ToyDisplayViewController: SceneViewController {
    var toyScene: ToyDisplayScene
    let accessibilityDescriptionView = UIView()
    
    public var topGradientColor: UIColor?
    public var bottomGradientColor: UIColor?
    
    var inactiveAccessibilityLabel: String? {
        get {
            return nil
        }
    }
    
    var activeAccessibilityLabel: String? {
        get {
            return NSLocalizedString("SpheroSimulator_AccessibilityDescription", value: "A simulation of Sphero rolling around as you command it.", comment: "VoiceOver description of Sphero simulator.")
        }
    }
    
    var accessibilityBottomAnchor: NSLayoutYAxisAnchor {
        get {
            return liveViewSafeAreaGuide.bottomAnchor
        }
    }
    
    public init() {
        toyScene = ToyDisplayScene()
        super.init(scene: toyScene)
        toyScene.safeFrameContainer = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        toyScene = ToyDisplayScene()
        
        super.init(coder: aDecoder)
        
        self.scene = toyScene
        toyScene.safeFrameContainer = self
    }
       
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        super.didReceiveRollMessage(heading: heading, speed: speed)
        
        toyScene.roll(heading: heading, speed: speed)
    }
    
    public override func didReceiveSetFrontPSILedMessage(color: UIColor) {
        super.didReceiveSetFrontPSILedMessage(color: color)
    }
    
    public override func didReceiveSetDomePositionMessage(angle: Double) {
        super.didReceiveSetDomePositionMessage(angle: angle)
        
        toyScene.setDomePosition(angle: angle)
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        toyScene.reset()
        
        accessibilityDescriptionView.accessibilityHint = activeAccessibilityLabel
        accessibilityDescriptionView.isAccessibilityElement = activeAccessibilityLabel != nil
    }
    
    public override func liveViewMessageConnectionClosed() {
        super.liveViewMessageConnectionClosed()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        spriteView.backgroundColor = .clear
        toyScene.backgroundColor = .clear
        toyScene.setOriginDotColor(#colorLiteral(red: 0.2652398944, green: 0.2723016441, blue: 0.5046583414, alpha: 1))
        
        setGradientBackground()
        
        view.insertSubview(accessibilityDescriptionView, aboveSubview: spriteView)
        accessibilityDescriptionView.accessibilityHint = inactiveAccessibilityLabel
        accessibilityDescriptionView.isAccessibilityElement = inactiveAccessibilityLabel != nil
        accessibilityDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            accessibilityDescriptionView.leadingAnchor.constraint(equalTo: liveViewSafeAreaGuide.leadingAnchor, constant: 20.0),
            accessibilityDescriptionView.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -20.0),
            accessibilityDescriptionView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 20.0),
            accessibilityDescriptionView.bottomAnchor.constraint(equalTo: accessibilityBottomAnchor, constant: -20.0)
        ])
    }
    
    private func setGradientBackground() {
        guard let colorTop = topGradientColor?.cgColor, let colorBottom = bottomGradientColor?.cgColor else {
            view.backgroundColor = .orange
            return
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(gradientLayer, below: spriteView.layer)
    }
}
