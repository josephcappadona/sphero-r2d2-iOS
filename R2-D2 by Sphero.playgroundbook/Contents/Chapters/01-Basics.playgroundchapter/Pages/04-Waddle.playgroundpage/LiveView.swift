//
//  LiveView.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

let waddleLiveViewController: WaddleLiveViewController = WaddleLiveViewController.instantiateFromStoryboard()
PlaygroundPage.current.liveView = waddleLiveViewController
PlaygroundPage.current.needsIndefiniteExecution = true
