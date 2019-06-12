//
//  AimingView.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-26.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(AimingView)
public class AimingView: UIView {
    
    let circleSizeRelative = 0.75 as CGFloat
    let handleSizeRelative = 0.1 as CGFloat
    
    public var onStartAiming: (()->())?
    public var onFinishAiming: (()->())?
    public var onHeadingChanged: ((Int)->())?
    
    private var timer: Timer?
    
    private var currentTouch: UITouch?
        
    private let circle = UIView()
    private var handle = UIView()
    
    private var currentAngle = 0.5 * CGFloat.pi
    private var lastResetAngle = 0.5 * CGFloat.pi
    
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
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        handle.translatesAutoresizingMaskIntoConstraints = false
        circle.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(circle)
        addSubview(handle)
        
        circle.layer.borderWidth = 3.0
        circle.layer.borderColor = UIColor.white.cgColor
    
        backgroundColor = .clear
    
        circle.backgroundColor = .clear
        handle.backgroundColor = #colorLiteral(red: 0.3715447187, green: 0.8178287745, blue: 0.9565852284, alpha: 1)
        
        NSLayoutConstraint.activate([
            handle.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: handleSizeRelative),
            handle.heightAnchor.constraint(equalTo: handle.widthAnchor, multiplier: 1.0),
            
            handle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            circle.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: circleSizeRelative),
            circle.heightAnchor.constraint(equalTo: circle.widthAnchor, multiplier: 1.0),
            
            circle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        self.isAccessibilityElement = true
        self.accessibilityTraits = UIAccessibilityTraitAdjustable
        self.accessibilityLabel = NSLocalizedString("aimingView.accessibilityDescription", value: "Aiming Control. Changes your robot\'s base heading.", comment: "VoiceOver description of a circular aiming control, used to rotate their toy.")
        
        update()
    }
    
    public override func accessibilityElementDidBecomeFocused() {
        onStartAiming?()
        
        sendHeading()
    }
    
    public override func accessibilityElementDidLoseFocus() {
        onFinishAiming?()
        
        lastResetAngle = currentAngle
    }
    
    public override func accessibilityIncrement() {
        super.accessibilityIncrement()
        
        currentAngle -= 0.1 * CGFloat.pi
        
        sendHeading()
        
        update()
    }
    
    public override func accessibilityDecrement() {
        super.accessibilityIncrement()
        
        currentAngle += 0.1 * CGFloat.pi
        
        sendHeading()
        
        update()
    }
    
    private func updateRadii() {
        let radius = 0.5 * frame.size.width
        
        layer.cornerRadius = radius
        handle.layer.cornerRadius = handleSizeRelative * radius
        circle.layer.cornerRadius = circleSizeRelative * radius
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if currentTouch == nil, let firstTouch = touches.first {
            currentTouch = firstTouch
            onStartAiming?()
            update()
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentTouch = currentTouch, touches.contains(currentTouch) {
            touchStopped()
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentTouch = currentTouch, touches.contains(currentTouch) {
            touchStopped()
        }
    }
    
    private func touchStopped() {
        if currentTouch == nil { return }
        
        self.currentTouch = nil
        
        onFinishAiming?()
        lastResetAngle = currentAngle
        
        update()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        update()
    }
    
    private func update() {
        updateCurrentAngle()
        updateHandlePosition()
        updateTimer()
    }
    
    private func updateCurrentAngle() {
        if let touch = currentTouch {
            let location = touch.location(in: self)
            
            let radius = 0.5 * frame.size.width
            
            let xDiff = location.x - radius
            let yDiff = radius - location.y
            
            let distance = hypot(xDiff, yDiff)
            
            if distance > 0.25 * radius {
                currentAngle = atan2(yDiff, xDiff)
            }
        }
    }
    
    private func updateHandlePosition() {
        
        let circleRadius = 0.5 * frame.size.width * circleSizeRelative
        
        let xTranslation = circleRadius * cos(currentAngle)
        let yTranslation = -circleRadius * sin(currentAngle)
        
        handle.layer.transform = CATransform3DTranslate(CATransform3DIdentity, xTranslation, yTranslation, 0.0)
    }
    
    private func updateTimer() {
        if currentTouch == nil, let timer = self.timer {
            self.timer = nil
            timer.invalidate()
        }
        
        if currentTouch != nil, timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true, block: { [weak self] (timer: Timer) in
                guard let `self` = self else { return }
                
                self.sendHeading()
            })
        }
    }
    
    private func sendHeading() {
        let relativeAngle = self.currentAngle - self.lastResetAngle
        
        let heading = Double(-relativeAngle * 180.0 / CGFloat.pi).canonizedAngle()
        
        onHeadingChanged?(Int(heading))
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateRadii()
        updateHandlePosition()
    }
}
