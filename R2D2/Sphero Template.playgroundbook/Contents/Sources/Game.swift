//
//  Game.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-17.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

public class Game {

    public let numPlayers: Int
    private var scores: [Int]

    private(set) var isGameOver = false

    /// Implement a custom algorithm for determining the winner
    public var checkForWinner = { () -> Int in
        return 0 // play forever
    }
    
    /// Invoked when points are scored
    public var onPlayerScored: ((_ number: Int, _ points: Int) -> Void)?
    
    /// Invoked when the game ends and a winner is declared
    public var onGameOver: ((_ winner: Int) -> Void)?
    
    public init(numPlayers: Int) {
        guard numPlayers > 0 else { fatalError("Invalid number of players!") }
        
        self.numPlayers = numPlayers
        self.scores = [Int]()
        
        for _ in 0..<numPlayers {
            self.scores.append(0)
        }
    }

    /// Start playing the game
    ///
    public func play() {
    }
    
    /// Score points for a given player number
    ///
    /// - Parameters:
    ///   - number: the player number [1...N]
    ///   - points: the number of points to add to the player's score
    public func player(number: Int, scored points: Int) -> Void {
        guard !isGameOver else { return }
        
        let index = number - 1
        guard index >= 0 && index < numPlayers else { return }
        
        scores[index] += points
        onPlayerScored?(number, points)
        
        let winner = checkForWinner()
        if winner > 0 && winner <= numPlayers {
            gameOver(winner: winner)
        }
    }
    
    public func gameOver(winner: Int) {
        isGameOver = true
        onGameOver?(winner)
    }
    
    /// Returns the score for a give player number
    ///
    /// - Parameter number: the player number [1...N]
    /// - Returns: the total number of points scored
    public func getScore(forPlayer number: Int) -> Int {
        let index = number - 1
        guard index >= 0 && index < numPlayers else { return 0 }
        
        return scores[index]
    }
    
}
