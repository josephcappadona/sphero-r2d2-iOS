//
//  Heap.swift
//  DeathStarEscape
//
//  Created by Anthony Blackman on 2017-06-22.
//  Copyright © 2017 Finger Food Studios Inc. All rights reserved.
//

import Foundation

public struct Heap<Element> {
    private var entries: [(value: Double, element: Element)] = []
    
    public mutating func push(element: Element, value: Double) {
        var curIndex = entries.count
        
        let entry = (value: value, element: element)
        entries.append(entry)
        
        while curIndex > 0 {
            let nextIndex = Heap.parentIndex(curIndex)
            if value >= entries[nextIndex].value {
                return
            }
            entries[curIndex] = entries[nextIndex]
            entries[nextIndex] = entry
            curIndex = nextIndex
        }
    }
    
    public mutating func popMin() -> Element? {
        if entries.isEmpty { return nil }
    
        let element = entries[0].element
        
        let lastEntry = entries.popLast()!
        
        if entries.isEmpty {
            return element
        }
        
        // replace min entry
        entries[0] = lastEntry
        var curIndex = 0
        
        while true {
            let left = Heap.leftChild(curIndex)
            
            if left >= entries.count { break }
            
            let right = left + 1
            
            let nextIndex: Int
            
            if right >= entries.count || entries[left].value < entries[right].value {
                nextIndex = left
            } else {
                nextIndex = right
            }
            
            if lastEntry.value < entries[nextIndex].value { break }
            
            entries[curIndex] = entries[nextIndex]
            entries[nextIndex] = lastEntry
            
            curIndex = nextIndex
        }
        
        return element
    }
    
    public var count: Int {
        get {
            return entries.count
        }
    }
    
    private static func parentIndex(_ index: Int) -> Int {
        return (index-1)/2
    }
    
    private static func leftChild(_ index: Int) -> Int {
        return 2*index + 1
    }
}
