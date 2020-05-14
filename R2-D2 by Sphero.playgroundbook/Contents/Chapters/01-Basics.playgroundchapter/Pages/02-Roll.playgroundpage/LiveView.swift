//
//  LiveView.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-20.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

let rollLiveViewController: RollLiveViewController = RollLiveViewController.instantiateFromStoryboard()

PlaygroundPage.current.liveView = rollLiveViewController
PlaygroundPage.current.needsIndefiniteExecution = true
