//
//  LiveView.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

let headSwivelLiveViewController: HeadSwivelLiveViewController = HeadSwivelLiveViewController.instantiateFromStoryboard()
PlaygroundPage.current.liveView = headSwivelLiveViewController
PlaygroundPage.current.needsIndefiniteExecution = true
