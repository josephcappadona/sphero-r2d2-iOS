//
//  LightsLiveViewController.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-07-06.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit
import PlaygroundSupport

@objc(LightsLiveViewController)
public class LightsLiveViewController: LiveViewController {
    public override class var existsInStoryboard: Bool {
        return true
    }
    
    private var isFlickering = false
    private var didStartFlickering = false
    private var flickerCallbacks = [()->()]()
    
    private var triangleLayer: CAShapeLayer? = nil
    private var triangleView = UIView()
    
    @IBOutlet var artooImageView: UIImageView!
    @IBOutlet var leiaImageView: UIImageView!

    @IBOutlet var artooContainerView: UIView!

    @IBOutlet var partialLeiaImageViews: [UIImageView]!
    @IBOutlet weak var backgroundCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var topSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundContainer: UIView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundContainer.isAccessibilityElement = true
        backgroundContainer.accessibilityLabel = NSLocalizedString("lights.accessibility.image", value: "R2D2 is in Obi-Wan Kenobi's house projecting a hologram of Princess Leia.", comment: "image accessibility, image is of R2-D2 projecting a hologram of princess Leia")
        view.insertSubview(triangleView, belowSubview: artooContainerView)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTriangle()
        
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.size.height
        
        if currentHeight < 300.0 {
            topSpacingConstraint.constant = 180.0
            backgroundCenterYConstraint.constant = -80.0
        } else if isVerticallyCompact() {
            topSpacingConstraint.constant = 200.0
            backgroundCenterYConstraint.constant = -50.0
        } else {
            topSpacingConstraint.constant = 200.0
            backgroundCenterYConstraint.constant = 0.0
        }
    }
    
    private func updateTriangle() {
        triangleLayer?.removeFromSuperlayer()
        triangleLayer = nil
        triangleView.frame = artooContainerView.bounds
        
        view.layoutIfNeeded()
        
        let path = UIBezierPath()
        
        path.move(to: CGPoint(
            x: artooImageView.frame.minX + 18.0,
            y: artooImageView.frame.minY + artooImageView.frame.height * 0.18
        ))
        
        path.addLine(to: CGPoint(
            x: leiaImageView.frame.midX,
            y: leiaImageView.frame.minY
        ))
        
        path.addLine(to: CGPoint(
            x: leiaImageView.frame.midX,
            y: leiaImageView.frame.maxY
        ))
        
        path.close()
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.frame = artooContainerView.frame
        layer.fillColor = #colorLiteral(red: 0.262745098, green: 0.6509803922, blue: 0.862745098, alpha: 0.25).cgColor
        layer.strokeColor = UIColor.clear.cgColor
        
        triangleView.layer.insertSublayer(layer, at: 0)
        triangleLayer = layer
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            UIView.animate(withDuration: 0.5) {
                self.leiaImageView.alpha = 0.0
                self.triangleView.alpha = 0.0
            }
        }
        
        didStartFlickering = false
    }
    
    public override func liveViewMessageConnectionClosed() {
        super.liveViewMessageConnectionClosed()
    
        DispatchQueue.main.async { [weak self] in
            self?.afterFlicker { [weak self] in
                self?.flickerOut()
            }
        }
    }
    
    private func flickerIn() {
        isFlickering = true
        
        UIView.animate(withDuration: 1.0, animations: {
            for view in self.partialLeiaImageViews {
                view.alpha = 1.0
            }
            self.triangleView.alpha = 1.0
        }) { [weak self] (finished: Bool) in
            guard let `self` = self else { return }
            
            self.leiaImageView.alpha = 1.0
            
            for view in self.partialLeiaImageViews {
                view.alpha = 0.0
            }
            
            self.stopFlickering()
        }
        
        flicker()
    }
    
    private func flickerOut() {
        isFlickering = true
        
        self.leiaImageView.alpha = 0.0
        
        for view in self.partialLeiaImageViews {
            view.alpha = 1.0
        }
        
        UIView.animate(withDuration: 1.0, animations: {
            for view in self.partialLeiaImageViews {
                view.alpha = 0.0
            }
            self.triangleView.alpha = 0.0
        }) { [weak self] (finished: Bool) in
            guard let `self` = self else { return }
            
            self.stopFlickering()
        }
        
        flicker()
    }
    
    private func flicker() {
        for view in partialLeiaImageViews {
            view.layer.setAffineTransform(CGAffineTransform(translationX: CGFloat(arc4random_uniform(10))-5.0, y: 0.0))
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) { [weak self] in
            guard let `self` = self,
                self.isFlickering
                else { return }
            
            self.flicker()
        }
    }
    
    private func stopFlickering() {
        isFlickering = false
            
        let callbacks = flickerCallbacks
        flickerCallbacks = []
        
        for callback in callbacks {
            callback()
        }
    }
    
    public override func onReceive(message: PlaygroundValue) {
        super.onReceive(message: message)
        
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.typeIdValue()
            else { return }
        
        switch typeId {
            case .setFrontPSILed, .setBackPSILed, .setHoloProjectorLed, .setLogicDisplayLed:
                if !didStartFlickering {
                    didStartFlickering = true
                    afterFlicker { [weak self] in
                        self?.flickerIn()
                    }
                }
                
            default:
                break
        }
        
    }
    
    private func afterFlicker(_ callback: @escaping ()->()) {
        if !isFlickering {
            callback()
        } else {
            flickerCallbacks.append(callback)
        }
    }
}
