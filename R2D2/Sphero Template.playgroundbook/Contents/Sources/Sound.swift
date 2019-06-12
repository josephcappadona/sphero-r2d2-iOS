//
//  Sound.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-04-20.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import AVFoundation

public class Sound {
    
    private let name: String
    private var player: AVAudioPlayer?
    private let volume: Float
    
    private static let queue = DispatchQueue(label: "com.sphero.sound.queue")
    
    internal init(_ name: String, ext: String = "mp3", volume: Float = 1.0) {
        self.name = name
        self.volume = volume
        
        Sound.queue.async {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
            
            self.player = try? AVAudioPlayer(contentsOf: url)
            self.player?.prepareToPlay()
            // Takes a while to load the first time.
            // Play it inaudibly.
            self.player?.volume = 0.0001
            self.player?.play()

        }
    }
    
    public func play() {
        Sound.queue.async {
            guard let player = self.player else { return }
            if player.isPlaying {
                player.stop()
            }
            player.currentTime = 0.0
            player.volume = self.volume
            player.prepareToPlay()
            player.play()
        }
    }
    
    public static let applause = Sound("Applause")
    public static let ding = Sound("Bell")
    public static let dizzy = Sound("Dizzy")
    public static let no = Sound("No")
    public static let sad = Sound("Sad")
    
    public static let complete = Sound("custom_sound")
    public static let success = Sound("winning_sound")
    public static let shake = Sound("shake_sound")
    public static let spin = Sound("spin_sound")
    public static let tap = Sound("tap_sound")
    public static let jump = Sound("toss_sound")
    
    public static let slowDown = Sound("roll_down")
    public static let fall = Sound("fall")
    public static let hit = Sound("stop")
    public static let speedUp = Sound("roll")
    public static let powerDown = Sound("power_down")
    public static let pop = Sound("dot_eaten")
    public static let bounce = Sound("eat_ghost")
    public static let plummet = Sound("game_over")
    public static let evilLaugh = Sound("ghost_laugh")
    public static let powerUp = Sound("power_up")
    
    public static let bell = Sound("Brass-Bell")
    public static let buttonPulse = Sound("ButtonPulse")
    public static let celebrate = Sound("Celebrate")
    public static let cheering = Sound("Cheering")
    public static let tick = Sound("Click")
    public static let lightning = Sound("lightning", volume: 0.1)
    public static let bleep = Sound("paddle", volume: 0.1)
    public static let sparkle = Sound("score", volume: 0.1)
    public static let bloop = Sound("wall", volume: 0.1)
    public static let grow = Sound("win", volume: 0.1)
    
    public static let allSounds = [
        applause, ding, dizzy, no, sad, complete, success, shake, spin, tap, jump, slowDown, fall, hit, speedUp, powerDown, pop, bounce, plummet, evilLaugh, powerUp, bell, buttonPulse, celebrate, cheering, tick, lightning, bleep, sparkle, bloop, grow
    ]
}
