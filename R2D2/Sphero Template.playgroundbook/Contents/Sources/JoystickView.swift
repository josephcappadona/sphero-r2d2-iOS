    //
//  JoystickView.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-25.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(JoystickView)
public class JoystickView: UIView {
    private var handle = UIView()
    private var circle = UIView()
    private var stickLayer: CAShapeLayer? = nil
    
    let handleSizeRelative = 0.35 as CGFloat
    let circleSizeRelative = 0.95 as CGFloat

    private var timer: Timer?
    
    private var currentTouch: UITouch?
    
    private var didSetUp = false
    
    public var onChange: ((_ x: Double, _ y: Double) -> ())?

    public init() {
        super.init(frame: CGRect(origin: .zero, size: .zero))
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public func setup() {
        if didSetUp { return }
        didSetUp = true
    
        translatesAutoresizingMaskIntoConstraints = false
        handle.translatesAutoresizingMaskIntoConstraints = false
        circle.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(circle)
        addSubview(handle)
        
        handle.backgroundColor = #colorLiteral(red: 0.3715447187, green: 0.8178287745, blue: 0.9565852284, alpha: 1)
        circle.backgroundColor = .white
        backgroundColor = #colorLiteral(red: 0.4436833858, green: 0.694622159, blue: 0.9670935273, alpha: 1)
        
        NSLayoutConstraint.activate([
            handle.widthAnchor.constraint(equalTo: widthAnchor, multiplier: handleSizeRelative),
            handle.heightAnchor.constraint(equalTo: handle.widthAnchor, multiplier: 1.0),
            
            handle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            circle.widthAnchor.constraint(equalTo: widthAnchor, multiplier: circleSizeRelative),
            circle.heightAnchor.constraint(equalTo: circle.widthAnchor, multiplier: 1.0),
            
            circle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        self.isAccessibilityElement = true
        self.accessibilityLabel = NSLocalizedString("joystickView.accessibilityDescription", value: "Joystick. Double tap and hold to drive your robot.", comment: "VoiceOver description of a joystick.")
    }
    
    private func updateRadii() {
        let radius = 0.5 * self.frame.size.width
        let handleRadius = handleSizeRelative * radius
        let circleRadius = circleSizeRelative * radius
        
        layer.cornerRadius = radius
        handle.layer.cornerRadius = handleRadius
        circle.layer.cornerRadius = circleRadius
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if currentTouch == nil {
            currentTouch = touches.first
            updateJoystickPosition()
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentTouch = currentTouch, touches.contains(currentTouch) {
            self.currentTouch = nil
        }
        updateJoystickPosition()
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentTouch = currentTouch, touches.contains(currentTouch) {
            self.currentTouch = nil
        }
        updateJoystickPosition()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateJoystickPosition()
    }
    
    private func updateJoystickPosition() {
        
        self.stickLayer?.removeFromSuperlayer()
        self.stickLayer = nil
        
        if let touch = currentTouch {
            let location = touch.location(in: self)
            
            let radius = 0.5 * frame.size.width
        
            var xTranslation = location.x - radius
            var yTranslation = location.y - radius
            
            var distance = hypot(xTranslation, yTranslation)
            
            if distance > radius {
                let scaleFactor = radius / distance
                xTranslation *= scaleFactor
                yTranslation *= scaleFactor
                distance = radius
            }
            
            handle.layer.transform = CATransform3DTranslate(CATransform3DIdentity, xTranslation, yTranslation, 0.0)
            
            let handleAngle = atan2(yTranslation, xTranslation)
            
            let stickPath = UIBezierPath()
            
            let xHat = xTranslation / distance
            let yHat = yTranslation / distance
            
            let baseSize = 0.1 * radius
            let topSize = 0.15 * radius
            
            stickPath.move(to: CGPoint(
                x: radius - baseSize * yHat,
                y: radius + baseSize * xHat
            ))
            
            stickPath.addArc(
                withCenter: CGPoint(x: radius, y: radius),
                radius: baseSize,
                startAngle: handleAngle + 0.5 * CGFloat.pi,
                endAngle: handleAngle - 0.5 * CGFloat.pi,
                clockwise: true
            )
            
            stickPath.addLine(to: CGPoint(
                x: radius + 0.9 * xTranslation + topSize * yHat,
                y: radius + 0.9 * yTranslation - topSize * xHat
            ))
            
            stickPath.addLine(to: CGPoint(
                x: radius + 0.9 * xTranslation - topSize * yHat,
                y: radius + 0.9 * yTranslation + topSize * xHat
            ))
            
            stickPath.close()
            
            let stickLayer = CAShapeLayer()
            stickLayer.path = stickPath.cgPath
            stickLayer.frame = CGRect(origin: .zero, size: self.frame.size)
            stickLayer.fillColor = UIColor.black.cgColor
            stickLayer.strokeColor = UIColor.black.cgColor
            stickLayer.lineWidth = 0.02 * frame.width
            
            self.layer.insertSublayer(stickLayer, below: handle.layer)
            self.stickLayer = stickLayer
            
        } else {
            handle.layer.transform = CATransform3DIdentity
        }
    }
    
    var lastSentHeading: Int? = nil
    var lastSentSpeed: Int? = nil
    public func enable() {
        if timer != nil { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 6.0, repeats: true, block: { [weak self] (timer: Timer) in
            guard let `self` = self else { return }
            
            if let touch = self.currentTouch {
            
                let location = touch.location(in: self)
                
                let radius = 0.5 * self.frame.size.width
            
                let xDiff = (location.x / radius) as CGFloat - 1.0
                let yDiff = (-location.y / radius) as CGFloat + 1.0
                
                self.onChange?(Double(xDiff), Double(yDiff))
            } else {
                self.onChange?(0,0)
            }
        })
    }
    
    public func disable() {
        if let timer = self.timer {
            self.timer = nil
            
            timer.invalidate()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateRadii()
    }
}
