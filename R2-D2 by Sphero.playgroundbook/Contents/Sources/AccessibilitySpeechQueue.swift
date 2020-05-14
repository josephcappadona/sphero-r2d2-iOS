//
//  AccessibilitySpeechQueue.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-04-13.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class AccessibilitySpeechQueue: NSObject, AVSpeechSynthesizerDelegate {
    typealias SpeechItem = (utterance: AVSpeechUtterance, timestamp: TimeInterval)
    
    public var onIdle: (()->())?
    
    private var queue = [SpeechItem]()
    
    private let speaker = AVSpeechSynthesizer()
    
    private(set) var isSpeaking = false
    
    public var maxDelayTime: TimeInterval = 5.0
    
    public var rate: Float = 0.66
    
    public override init() {
        super.init()
        
        speaker.delegate = self
    }
    
    public func speak(_ message: String, isVoiceOverOnly: Bool = true, pitch: Float = 1.0) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = self.rate
        utterance.pitchMultiplier = pitch
        
        if isVoiceOverOnly && !UIAccessibilityIsVoiceOverRunning() {
            return
        }
        
        let item: SpeechItem = (
            utterance: utterance,
            timestamp: Date().timeIntervalSince1970
        )
        
        // Run all operations on the main thread to avoid race conditions.
        DispatchQueue.main.async {
            self.queue.append(item)
            self.startSpeaking()
        }
    }
    
    private func startSpeaking() {
        let now = Date().timeIntervalSince1970
        
        queue = queue.filter { item in
            return now - item.timestamp < maxDelayTime
        }
        
        if queue.isEmpty {
            onIdle?()
            
            return
        }
        
        if isSpeaking { return }
        
        let item = queue.removeFirst()
        
        speaker.speak(item.utterance)
    }
    
    private func didFinishSpeaking() {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.startSpeaking()
        }
    }
    
    public func reset() {
        queue.removeAll()
        
        onIdle?()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishSpeaking()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        didFinishSpeaking()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
}
