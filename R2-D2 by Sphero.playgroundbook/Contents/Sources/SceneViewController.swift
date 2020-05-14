//
//  SceneViewController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-03.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

@objc(SceneViewController)
public class SceneViewController: LiveViewController, SafeFrameContainer {

	var spriteView: SKView!
	var scene: SKScene?
    
    public var shouldPutSceneInSafeContainer = false
	
	public init(scene: SKScene) {
		self.scene = scene
		
		super.init(nibName: nil, bundle: nil)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		
		spriteView = SKView()
		spriteView.showsDrawCount = false
		spriteView.showsNodeCount = false
		spriteView.showsFPS = false
		spriteView.preferredFramesPerSecond = 30
		
        view.insertSubview(spriteView, at: 0)
		
		spriteView.translatesAutoresizingMaskIntoConstraints = false
		
        setupConstraints()
		
        if let scene = scene {
            spriteView.presentScene(scene)
        }
	}
    
    func setupConstraints() {
        if shouldPutSceneInSafeContainer {
            view.addConstraints([
                NSLayoutConstraint(item: spriteView, attribute: .top, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .top, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: spriteView, attribute: .bottom, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: spriteView, attribute: .left, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .left, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: spriteView, attribute: .right, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .right, multiplier: 1.0, constant: 0.0)
            ])
        } else {
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[spriteView]|", options:[], metrics: [:], views: ["spriteView":spriteView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[spriteView]|", options: [], metrics: [:], views: ["spriteView":spriteView]))
        }
    }
    
    public override var shouldAutorotate: Bool {
		return false
	}

	public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.landscapeRight
	}

	public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIInterfaceOrientation.landscapeRight
	}
}
