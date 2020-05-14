//
//  DeathStarScanningViewController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-05.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

@objc (DeathStarScanningViewController)
public class DeathStarScanningViewController: DeathStarViewController {
    open override class var scene: DeathStarEscapeScene {
        get {
            return DeathStarScanningScene()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundContainer?.accessibilityLabel = NSLocalizedString("scanning.accessibility.label", value: "R2D2 is in a hallway of the Death Star with its life form scanner rotating back and forth scanning for stormtroopers.", comment: "scanning screen, image accessibility. image is of r2-d2 with its life form scanner (antenna from its dome) out.")
    }
    
}

public class DeathStarScanningScene: DeathStarEscapeScene {
    open override var maze: DeathStarMaze {
        get {
            return .scanningMaze
        }
    }
}
