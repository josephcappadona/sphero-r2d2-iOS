//
//  RollLiveViewController.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-07-06.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import SpriteKit
import PlaygroundSupport

@objc(RollLiveViewController)
public class RollLiveViewController: ToyDisplayViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundContainer: UIView!
    
    @IBOutlet weak var backgroundCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundZoomedInHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundZoomedInWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundZoomedOutWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundZoomedOutHeightConstraint: NSLayoutConstraint!
    
    public override var topGradientColor: UIColor? {
        get {
            return #colorLiteral(red: 0.6837405562, green: 0.7685381174, blue: 0.7938773036, alpha: 1)
        }
        
        set {
            super.topGradientColor = newValue
        }
    }
    
    public override var bottomGradientColor: UIColor? {
        get {
            return #colorLiteral(red: 0.4173973501, green: 0.4901130199, blue: 0.511246562, alpha: 1)
        }
        
        set {
            super.topGradientColor = newValue
        }
    }
    
    public override class var existsInStoryboard: Bool {
        return true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundContainer.isAccessibilityElement = true
        backgroundContainer.accessibilityLabel = NSLocalizedString("roll.accessibility.label", value: "R2D2 standing in a hallway in front of a door ready to roll away.", comment: "image accessibility for the roll screen")
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !isLiveViewMessageConnectionOpened {
            backgroundImageView?.isHidden = isVeryCompact()
        }
    }
    
    public override func updateViewConstraints() {
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.size.height
        let currentWidth = liveViewSafeAreaGuide.layoutFrame.size.width
        
        NSLayoutConstraint.deactivate([backgroundZoomedInHeightConstraint, backgroundZoomedInWidthConstraint,
                                       backgroundZoomedOutWidthConstraint, backgroundZoomedOutHeightConstraint])
        //ipad pro
        if currentHeight > 1024 || currentWidth > 1024 {
            backgroundCenterYConstraint.constant = 0.0
            NSLayoutConstraint.activate([backgroundZoomedOutWidthConstraint, backgroundZoomedOutHeightConstraint])
        } else {
            backgroundCenterYConstraint.constant = 50.0
            NSLayoutConstraint.activate([backgroundZoomedInWidthConstraint, backgroundZoomedInHeightConstraint])
        }
        
        super.updateViewConstraints()
    }
    
    override func sendToyReadyMessage() {
        super.sendToyReadyMessage()
        backgroundContainer.isHidden = true
    }
    
    public override func onReceive(message: PlaygroundValue) {
        super.onReceive(message: message)
        
        guard let dict = message.dictValue(),
            let type = dict[MessageKeys.type]?.typeIdValue()
            else { return }
        
        if type == .showEscapePod {
            let escapePod = SKSpriteNode(imageNamed: "escape_pod")
            
            escapePod.position.x = toyScene.toyNode.position.x
            escapePod.position.y = toyScene.toyNode.position.y + 230.0
            
            escapePod.alpha = 0.0
            escapePod.run(.fadeIn(withDuration: 1.6))
            
            toyScene.addExtraNode(escapePod)
        }
    }
}
