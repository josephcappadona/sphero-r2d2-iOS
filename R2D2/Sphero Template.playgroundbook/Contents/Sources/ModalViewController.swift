//
//  ModalViewController.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-05-01.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit

open class ModalViewController: UIViewController {

    open func animateIn(callback: @escaping (Bool) -> Void) {
        callback(false)
    }
    
    open func animateOut(callback: @escaping (Bool) -> Void) {
        callback(false)
    }
    
    open var insetLayoutGuide: UILayoutGuide?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
