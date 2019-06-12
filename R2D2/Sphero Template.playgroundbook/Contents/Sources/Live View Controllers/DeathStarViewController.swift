//
//  DeathStarViewController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-26.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit
import SpriteKit
import PlaygroundSupport

@objc (DeathStarViewController)
public class DeathStarViewController: LiveViewController {

    lazy var skView = SKView()
    @IBOutlet weak var centerYConstraint: NSLayoutConstraint!
    
    public override class var existsInStoryboard: Bool {
        return true
    }
    
    open class var scene: DeathStarEscapeScene {
        get {
            return DeathStarEscapeScene()
        }
    }
    
    lazy var scene: DeathStarEscapeScene = {
        return type(of: self).scene
    }()
    
    public override var shouldPresentAim: Bool {
        get {
            return false
        }
    }
    
    @IBOutlet weak var backgroundContainer: UIView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        scene.liveView = self
        
        view.insertSubview(skView, belowSubview: backgroundContainer ?? connectionHintArrowView)
        
        skView.pinEdges(to: view)
        skView.translatesAutoresizingMaskIntoConstraints = false
        
        scene.isRunning = false
        
        skView.presentScene(scene)
        
        skView.isAccessibilityElement = true
        skView.accessibilityLabel = NSLocalizedString("deathStar.accessibility.sceneDescription", value: "R2D2 in the Death Star. Double tap, hold, then slide your finger to control R2D2.", comment: "death star accessibility string. Description on how to control R2-d2")
        
        backgroundContainer?.accessibilityLabel = NSLocalizedString("finalMission.accessibility.label", value: "R2D2 is rolling up the Millennium Falcon ramp, escaping from the Death Star.", comment: "final mission accessibility, image is of r2d2 rolling up the space ship's ramp to escape from the death star.")
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !isLiveViewMessageConnectionOpened {
            backgroundContainer?.isHidden = isVeryCompact()
        }
        
        if isVerticallyCompact() {
            centerYConstraint?.constant = -30.0
        } else {
            centerYConstraint?.constant = 0.0
        }
    }
    
    override func sendToyReadyMessage() {
        super.sendToyReadyMessage()
        
        connectedToy?.setFrontPSILed(color: .red)
        connectedToy?.setBackPSILed(color: .black)
        connectedToy?.setLogicDisplayLeds(brightness: 0.0)
        connectedToy?.setHoloProjectorLed(brightness: 0.0)
        connectedToy?.setDomePosition(angle: 0.0)
        
        scene.isRunning = true
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        UIView.animate(withDuration: 0.2) {
            self.backgroundContainer?.alpha = 0.0
        }
        
        // Go back to the start on reset.
        scene.checkpoint = nil
        scene.artooNode.wasCaptured = false
        
        scene.reset()
        scene.speakOpenDirections()
    }
    
    public override func liveViewMessageConnectionClosed() {
        super.liveViewMessageConnectionClosed()
        
        connectedToy?.stopAudio()
        scene.isRunning = false
    }
    
    public override func onReceive(message: PlaygroundValue) {
        super.onReceive(message: message)
        
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue(),
            typeId == MessageTypeId.hackingCodeEntered.rawValue,
            let code = dict[MessageKeys.code]?.intValue()
            else { return }
        
        self.scene.artooNode.enterDoorCode(code)
    }
}

