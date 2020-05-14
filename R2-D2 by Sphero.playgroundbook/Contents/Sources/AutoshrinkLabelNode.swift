//
//  AutoshrinkLabelNode.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-04-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class AutoshrinkLabelNode: SKLabelNode {
    private var _maxWidth: CGFloat = 0.0
    
    public var maxWidth: CGFloat {
        get {
            return _maxWidth
        }
        
        set {
            _maxWidth = newValue
            xScale = min(1.0, xScale * _maxWidth / frame.size.width)
        }
    }
}
