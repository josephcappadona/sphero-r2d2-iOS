//
//  DeathStarHackingViewController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-04.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

@objc (DeathStarHackingViewController)
public class DeathStarHackingViewController: DeathStarViewController {
    @IBOutlet weak var backgroundCenterYConstraint: NSLayoutConstraint!
    
    open override class var scene: DeathStarEscapeScene {
        get {
            return DeathStarHackingScene()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundContainer?.accessibilityLabel = NSLocalizedString("hacking.accessibility.label", value: "R2D2 is in front of a blast door of the Death Star trying to hack the code to open the door.", comment: "hacking screen, image accessibility. image is of r2-d2 in front of a blast door.")
    }
}

public class DeathStarHackingScene: DeathStarEscapeScene {
    open override var maze: DeathStarMaze {
        get {
            return .hackingMaze
        }
    }
    
    public let hackingPanelNode = SKSpriteNode(imageNamed: "garbageCompactorPanel")
    
    public let code = 1138
    
    public override func reset() {
        super.reset()
        
        hackingPanelNode.position = self.maze.endLocation
        hackingPanelNode.position.y += DeathStarCell.size
        
        addChild(hackingPanelNode)
    }
}
