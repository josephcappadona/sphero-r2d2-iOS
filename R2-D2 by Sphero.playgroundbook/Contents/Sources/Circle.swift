//
//  Circle.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-06-29.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

public struct Circle {
    let center: CGPoint
    let radius: CGFloat
    
    public func contains(_ point: CGPoint) -> Bool {
        return hypot(center.x - point.x, center.y - point.y) <= radius
    }
    
    // http://www.cs.uu.nl/docs/vakken/ga/slides4b.pdf
    public static func smallest(containing points: [CGPoint]) -> Circle {
        // Shuffling first ensures O(n) expected time.
        var shuffledPoints = points
        shuffledPoints.shuffle()
        
        return Circle.smallest(containingPoints: shuffledPoints.suffix(from: 0), withBoundaryPoints: [])
    }
    
    private static func smallest(containingPoints points: ArraySlice<CGPoint>, withBoundaryPoints boundaryPoints: [CGPoint]) -> Circle {
        var circle: Circle

        if boundaryPoints.count == 3 {
            // Given 3 boundary points we can compute the circle directly.
            return Circle.through(boundaryPoints[0], boundaryPoints[1], boundaryPoints[2])
        }
        if boundaryPoints.count == 2 {
            let p = boundaryPoints[0]
            let q = boundaryPoints[1]
            circle = Circle(
                center: CGPoint(x: 0.5 * (p.x + q.x), y: 0.5 * (p.y + q.y)),
                radius: 0.5 * hypot(p.x - q.x, p.y - q.y)
            )
        } else if boundaryPoints.count == 1 {
            circle = Circle(
                center: boundaryPoints[0],
                radius: 0.0
            )
        } else {
            circle = Circle(
                center: .zero,
                radius: 0.0
            )
        }
        
        for newPointIndex in points.indices {
            let newPoint = points[newPointIndex]
            
            if !circle.contains(newPoint) {
                var subBoundaryPoints = boundaryPoints
                subBoundaryPoints.append(newPoint)
                circle = Circle.smallest(containingPoints: points.prefix(upTo: newPointIndex), withBoundaryPoints: subBoundaryPoints)
            }
        }
        
        return circle
    }
    
    private static func through(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Circle {
        // p0 and p1 are the midpoints of ab and ac
        let p0 = CGPoint(x: 0.5 * (a.x + b.x), y: 0.5 * (a.y + b.y))
        let p1 = CGPoint(x: 0.5 * (a.x + c.x), y: 0.5 * (a.y + c.y))
        
        // v0 and v1 are orthogonal vectors of ab and ac
        let v0 = CGPoint(x: b.y - a.y, y: a.x - b.x)
        let v1 = CGPoint(x: c.y - a.y, y: a.x - c.x)
        
        // compute lambda0 such that p0 + lambda0 * v0 intersects with the line p1 + lambda1 * v1
        // This intersection point is the center of the circle.
        let numerator = v1.y*(p0.x - p1.x) - v1.x*(p0.y - p1.y)
        let denominator = v1.x*v0.y - v1.y*v0.x
        let lambda0 = numerator / denominator
        
        let center = CGPoint(
            x: p0.x + lambda0 * v0.x,
            y: p0.y + lambda0 * v0.y
        )
        
        let radius = hypot(center.x - a.x, center.y - a.y)
        
        return Circle(
            center: center,
            radius: radius
        )
    }
}



