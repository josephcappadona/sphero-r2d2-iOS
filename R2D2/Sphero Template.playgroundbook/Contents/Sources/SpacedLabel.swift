//
//  SpacedLabel.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-27.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit

@objc(SpacedLabel)
@IBDesignable public class SpacedLabel: UILabel {
    
    private var _characterSpacing: CGFloat = 0.0
    
    @IBInspectable var characterSpacing: CGFloat {
        get {
            return _characterSpacing
        }
        
        set(spacing) {
            _characterSpacing = spacing
            updateSpacing()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
    
        set(radius) {
            self.layer.cornerRadius = radius
            setNeedsDisplay()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        updateSpacing()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateSpacing()
    }
    
    public override var text: String? {
        get {
            return super.text
        }
        
        set(value) {
            super.text = value
            updateSpacing()
        }
    }
    
    private func updateSpacing() {
        
        let text = self.text ?? ""
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSKernAttributeName, value: _characterSpacing, range: NSMakeRange(0, text.count))
        
        self.attributedText = attributedString
 
        self.setNeedsDisplay()
    }
    
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        updateSpacing()
    }
}
