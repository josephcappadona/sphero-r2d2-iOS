//
//  DeathStarAssessmentController.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-07.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport
import UIKit

public class HackingState {
    public var isCancelled = false
    public var doorCode: Int
    public var enteredCode: Int? = nil
    public var codeLowerBound: Int? = nil
    public var codeUpperBound: Int? = nil
    public var receivedResponse = false
    public var lock = NSCondition()
    
    public init(doorCode: Int) {
        self.doorCode = doorCode
    }
}

// AssessmentController has setBackPSILed and setFrontPSILed methods,
// so the content helper functions can't be called from within an AssessmentController.
// Use a helper function outside of the controller instead.
fileprivate func turnLights(on: Bool) {
    setFrontPSILed(color: on ? .blue : .black)
    setBackPSILed(color: on ? .yellow : .black)
}


open class DeathStarAssessmentController: AssessmentController {
    private static let hackingStateKey = "com.sphero.deathStar.hackingState"
    
    public var hack: (()->())? = nil
    public var stormtrooperNearby: ((Double)->())? = nil
    
    private let hackingQueue = DispatchQueue(label: "com.sphero.deathStar.hacking.queue")
    
    private var hackingThread: Thread? = nil
    
    private var hackingThreadState: HackingState? {
        return hackingThread?.threadDictionary[DeathStarAssessmentController.hackingStateKey] as? HackingState
    }
    
    public var state: HackingState? {
        get {
            return Thread.current.threadDictionary[DeathStarAssessmentController.hackingStateKey] as? HackingState
        }
        
        set {
            Thread.current.threadDictionary[DeathStarAssessmentController.hackingStateKey] = newValue
        }
    }
    private var areHackingLightsOn = false
    
    private static let finishedScanningKey = "com.sphero.deathStar.finishedScanning"
    private var currentScanningThread: Thread? = nil

    public var scan: (()->())? = nil

    private let scanQueue = DispatchQueue(label: "com.sphero.deathStar.scanning.queue", attributes: .concurrent)
    
    private let stormtrooperQueue = DispatchQueue(label: "com.sphero.deathStar.stormtrooper.queue", attributes: .concurrent)
    
    open func hackingStarted() { }
    open func hackingFinished() { }
    open func codeEntered(_ code: Int) { }
    open func scanningFinished() { }
    open func scanningStarted() { }
    open func onStormtrooperNearby(distance: Double) { }
    open func onStormtrooperCodeFinished() { }
    
    public func isScanning() -> Bool {
        let finished = Thread.current.threadDictionary[DeathStarAssessmentController.finishedScanningKey]
        
        if let finished = finished as? Bool {
            return !finished
        } else {
            return false
        }
    }
    
    open override func onMessage(_ message: PlaygroundValue) {
        super.onMessage(message)
        
        guard let dict = message.dictValue(),
            let typeRaw = dict[MessageKeys.type]?.intValue(),
            let type = MessageTypeId(rawValue: typeRaw)
            else { return }
        
        if type == .hackingStart {
            guard let doorCode = dict[MessageKeys.code]?.intValue() else { return }
            
            areHackingLightsOn = true
            turnLights(on: true)
            
            if let hack = self.hack {
                self.hackingStarted()
                
                hackingQueue.async { [weak self] in
                    guard let `self` = self else { return }
                    
                    let state = HackingState(doorCode: doorCode)
                    self.state = state
                    self.hackingThread = Thread.current
                    
                    state.lock.lock()
                    hack()
                    self.hackingFinished()
                    state.lock.unlock()
                }
            }
        }
        
        if type == .hackingContinue,
            let state = hackingThreadState {
            state.lock.lock()
            state.receivedResponse = true
            
            areHackingLightsOn = !areHackingLightsOn
            turnLights(on: areHackingLightsOn)
            
            state.lock.broadcast()
            state.lock.unlock()
        }
        
        if type == .hackingCancelled,
            let state = hackingThreadState {
            state.lock.lock()
            state.receivedResponse = true
            state.isCancelled = true
            
            areHackingLightsOn = false
            turnLights(on: false)
            
            state.lock.broadcast()
            state.lock.unlock()
        }
        
        if type == .artooReachedEnd {
            let message = NSLocalizedString("deathStarMovement.assessment.pass", value: "### Congratulations! \nYou successfully made it through this part of the Death Star!\nOn to the [next page](@next)!", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nYou successfully made it through this part of the Death Star!\nOn to the [next page]'")
            makeAssessment(status: .pass(message: message))
        }
        
        if type == .stormtrooperDistance,
            let distance = dict[MessageKeys.distance]?.doubleValue() {
            
            stormtrooperQueue.async { [weak self] in
                self?.onStormtrooperNearby(distance: distance)
                
                self?.stormtrooperNearby?(distance)
                
                self?.onStormtrooperCodeFinished()
            }
        }
        
        if type == .scanStart {
            self.currentScanningThread = nil
            scanQueue.async { [weak self] in
                guard let `self` = self else { return }
                Thread.current.threadDictionary[DeathStarAssessmentController.finishedScanningKey] = false
                self.currentScanningThread = Thread.current
                self.scanningStarted()
                self.scan?()
                self.scanningFinished()
            }
        }
        
        if type == .scanStop,
            let scanThread = currentScanningThread {
            scanThread.threadDictionary[DeathStarAssessmentController.finishedScanningKey] = true
            
            setDomePosition(angle: 0.0)
            self.scanningFinished()
        }
    }
    
    public func enter(code: Int) {
        codeEntered(code)
        
        guard let state = self.state else { return }
        
        let doorCode = state.doorCode
        
        if code < doorCode {
            state.codeLowerBound = code
        } else if code > doorCode {
            state.codeUpperBound = code
        }
        
        let isCorrect = code == doorCode
        
        state.enteredCode = code
        state.receivedResponse = false
        
        PlaygroundHelpers.sendMessageToLiveView(
            .dictionary([
                MessageKeys.type: MessageTypeId.hackingCodeEntered.playgroundValue(),
                MessageKeys.code: .integer(code)
            ])
        )
        
        if !isCorrect {
            while !state.receivedResponse && !state.isCancelled {
                state.lock.wait()
            }
        }
        
        else {
            areHackingLightsOn = false
            turnLights(on: false)
        }
    }
}
