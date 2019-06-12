//
//  DeathStarStormtrooperViewController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-05.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

@objc (DeathStarStormtrooperViewController)
public class DeathStarStormtrooperViewController: DeathStarViewController {
    
    @IBOutlet weak var artooBottomConstraint: NSLayoutConstraint!
    
    open override class var scene: DeathStarEscapeScene {
        get {
            return DeathStarStormtrooperScene()
        }
    }
    
    @IBOutlet weak var artooImageView: UIImageView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        artooImageView.transform = CGAffineTransform.init(rotationAngle: (.pi * (10.0) / 180.0) as CGFloat)
        
        backgroundContainer?.accessibilityLabel = NSLocalizedString("stormtrooper.accessibility.label", value: "R2D2 is in a hallway of the Death Star hiding from a stormtrooper.", comment: "stormtrooper screen, image accessibility. image is of r2-d2 hiding in the hallway from a stormtrooper.")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isVerticallyCompact() && !isVeryCompact() {
            artooBottomConstraint.constant = -30.0
        } else {
            artooBottomConstraint.constant = -12.0
        }
    }
}

public class DeathStarStormtrooperScene: DeathStarEscapeScene {
    open override var maze: DeathStarMaze {
        get {
            return .stormtrooperMaze
        }
    }
    
    open override var isScanEnabled: Bool {
        return false
    }
}
