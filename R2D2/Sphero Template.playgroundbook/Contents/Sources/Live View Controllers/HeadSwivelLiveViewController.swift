//
//  HeadSwivelLiveViewController.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-07-06.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit
import SpriteKit
import PlaygroundSupport

@objc(HeadSwivelLiveViewController)
public class HeadSwivelLiveViewController: ToyDisplayViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var foregroundImageView: UIImageView!
    
    public override class var existsInStoryboard: Bool {
        return true
    }
    
    public override var topGradientColor: UIColor? {
        get {
            return #colorLiteral(red: 0.6470588235, green: 0.3294117647, blue: 0.4431372549, alpha: 1)
        }
        
        set {
            super.topGradientColor = newValue
        }
    }
    
    public override var bottomGradientColor: UIColor? {
        get {
            return #colorLiteral(red: 0.3647058824, green: 0.1921568627, blue: 0.3098039216, alpha: 1)
        }
        
        set {
            super.topGradientColor = newValue
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        foregroundImageView.accessibilityLabel = NSLocalizedString("headSwivel.accessibility.text", value: "R2D2 is in a desert canyon.", comment: "image accessibility, image is of R2-D2 in a desert canyon.")
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !isLiveViewMessageConnectionOpened {
            backgroundImageView.isHidden = isVeryCompact()
            foregroundImageView.isHidden = isVeryCompact()
        }
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        backgroundImageView.isHidden = true
        foregroundImageView.isHidden = true
    }
    
}
