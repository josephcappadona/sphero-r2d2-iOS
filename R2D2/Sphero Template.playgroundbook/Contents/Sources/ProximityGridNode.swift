//
//  ProximityGridNode.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-07-17.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit

public class ProximityGridNode: SKNode {
    public let maxDistance: CGFloat
    public let followingNode: SKNode
    
    private var grid = [[SKNode]]()
    
    private var currentChildIndices = [(xIndex: Int, yIndex: Int)]()
    
    public init(followingNode: SKNode, maxDistance: CGFloat) {
        self.followingNode = followingNode
        self.maxDistance = maxDistance
        
        super.init()
    }
    
    public func addGridChild(node: SKNode) {
        let nodeIndices = indices(forPoint: node.position)
        
        let followingIndices = indices(forPoint: followingNode.position)
        
        while nodeIndices.yIndex >= grid.count {
            grid.append([])
        }
        
        while nodeIndices.xIndex >= grid[nodeIndices.yIndex].count {
            let newNode = SKNode()
            let newNodeY = nodeIndices.yIndex
            let newNodeX = grid[nodeIndices.yIndex].count
            
            if (abs(newNodeY - followingIndices.yIndex) as Int) <= 1 && (abs(newNodeX - followingIndices.xIndex) as Int) <= 1  {
                addChild(newNode)
                currentChildIndices.append((xIndex: newNodeX, yIndex: newNodeY))
            }
            
            grid[nodeIndices.yIndex].append(newNode)
        }
        
        grid[nodeIndices.yIndex][nodeIndices.xIndex].addChild(node)
    }
    
    public func update() {
    
        let nodeIndices = indices(forPoint: followingNode.position)
    
        for (indicesIndex,childIndices) in currentChildIndices.enumerated() {
            let (xIndex,yIndex) = childIndices
            let childNode = grid[yIndex][xIndex]
            if childNode.parent == nil { continue }
        
            if abs(xIndex - nodeIndices.xIndex) as Int > 1 || abs(yIndex - nodeIndices.yIndex) as Int > 1 {
                childNode.removeFromParent()
                currentChildIndices.remove(at: indicesIndex)
                
                // Only do one add / remove per frame.
                // Adds and removes with physics bodies are expensive,
                // and with R2-D2's max speed it's still impossible to make it to an unloaded wall this way.
                return
            }
        }
        
        for y in nodeIndices.yIndex-1 ... nodeIndices.yIndex+1 {
            if y < 0 || y >= grid.count { continue }
            
            let row = grid[y]
            
            for x in nodeIndices.xIndex-1 ... nodeIndices.xIndex+1 {
                if x < 0 || x >= row.count { continue }
                
                if row[x].parent != nil { continue }
                
                addChild(row[x])
                currentChildIndices.append((xIndex: x, yIndex: y))
                
                // Only one add / remove per frame.
                // See above comment.
                return
            }
        }
    }
    
    private func indices(forPoint point: CGPoint) -> (xIndex: Int, yIndex: Int) {
        return (
            xIndex: Int(point.x / maxDistance),
            yIndex: Int(-point.y / maxDistance)
        )
    }
    
    public func reset() {
        removeAllChildren()
        grid = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
