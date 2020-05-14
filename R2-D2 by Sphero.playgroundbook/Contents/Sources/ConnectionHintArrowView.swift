//
//  ConnectionHintArrowView.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-04-28.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

public class ConnectionHintArrowView: UIView {
    private var arrowImageView: UIImageView?
    private let arrowImage = #imageLiteral(resourceName: "connectHintArrow")
    
    public func show() {
        if arrowImageView != nil { return }
    
        let imageView = UIImageView()
        imageView.image = arrowImage
        
        arrowImageView = imageView
        
        imageView.frame.size = arrowImage.size
        imageView.frame.origin.x = -arrowImage.size.width
        imageView.frame.origin.y = 14.0
        
        addSubview(imageView)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        UIView.setAnimationCurve(.easeOut)
        UIView.setAnimationRepeatAutoreverses(true)
        UIView.setAnimationRepeatCount(.infinity)
        
        imageView.frame.origin.x -= 20
        
        UIView.commitAnimations()
    }
    
    public func hide() {
        arrowImageView?.removeFromSuperview()
        arrowImageView = nil
    }
}
