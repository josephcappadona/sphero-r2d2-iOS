//
//  WaddleLiveViewController.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-07-06.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit
import SpriteKit
import PlaygroundSupport

@objc(WaddleLiveViewController)
public class WaddleLiveViewController: LiveViewController {
    public override class var existsInStoryboard: Bool {
        return true
    }
    
    @IBOutlet var artooImageView: UIImageView!
    @IBOutlet weak var frontAccessibilityImageView: UIImageView!
    @IBOutlet weak var leftWiggleLine: UIImageView!
    @IBOutlet weak var rightWiggleLine: UIImageView!
    
    private var isWaddling = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        frontAccessibilityImageView.accessibilityLabel = NSLocalizedString("waddle.accessibility.text", value: "R2D2 is in the desert, waddling back and forth to warn friends of danger.", comment: "image accessibility, image is of R2-D2 in the desert with shaky lines beside it indictating movement.")
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        leftWiggleLine.isHidden = true
        rightWiggleLine.isHidden = true
    }
    
    public override func didReceiveSetStanceMessage(stance: StanceCommand.StanceId) {
        super.didReceiveSetStanceMessage(stance: stance)
        
        if stance == .waddle {
            startWaddling()
        } else {
            stopWaddling()
        }
    }
    
    private func startWaddling() {
        if !isWaddling {
            isWaddling = true
            leftWiggleLine.isHidden = false
            rightWiggleLine.isHidden = false
            waddle(direction: 1.0)
        }
    }
    
    private func stopWaddling() {
        isWaddling = false
        leftWiggleLine.isHidden = true
        rightWiggleLine.isHidden = true
    }
    
    private func waddle(direction: CGFloat) {
        if !isWaddling {
            UIView.animate(withDuration: 0.5, animations: {
                self.artooImageView.transform = .identity
            })
            
            self.leftWiggleLine.transform = .identity
            self.leftWiggleLine.layer.removeAllAnimations()
            self.rightWiggleLine.transform = .identity
            self.rightWiggleLine.layer.removeAllAnimations()
            
            return
        }
    
        UIView.animate(withDuration: 0.3, animations: {
            self.artooImageView.transform = CGAffineTransform(rotationAngle: direction * CGFloat.pi * 0.02)
                .concatenating(CGAffineTransform(translationX: 8.0 * direction, y: 0.0))
        }) { [weak self] (finished: Bool) in
            self?.waddle(direction: -direction)
        }
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.repeat, .autoreverse], animations: {
            self.leftWiggleLine.transform = CGAffineTransform(translationX: 5.0, y: 0.0)
            self.rightWiggleLine.transform = CGAffineTransform(translationX: 5.0, y: 0.0)
        }, completion: nil)
    }
}
