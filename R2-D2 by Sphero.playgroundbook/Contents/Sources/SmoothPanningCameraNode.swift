//
//  SmoothPanningCameraNode.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-24.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import SpriteKit
import UIKit

public class SmoothPanningCameraNode: SKCameraNode {
    
    private var currentVelocity = CGVector.zero
    private var currentScaleSpeed: CGFloat = 0.0
    private var maxAcceleration: CGFloat = 1.0
    private var maxScaleAcceleration: CGFloat = 0.1
    
    private var velocityFactor: CGFloat = 0.1
    private var shouldCutNextMovement = false
    
    public func panTowards(desiredPosition: CGPoint, desiredScale: CGFloat) {
        
        if shouldCutNextMovement {
            cutTo(position: desiredPosition, scale: desiredScale)
            shouldCutNextMovement = false
            return
        }
        
        let desiredVelocityX = (desiredPosition.x - position.x) * velocityFactor
        let desiredVelocityY = (desiredPosition.y - position.y) * velocityFactor
        
        var accelerationX = desiredVelocityX - currentVelocity.dx
        var accelerationY = desiredVelocityY - currentVelocity.dy
        
        let accelerationMagnitude = hypot(accelerationX, accelerationY)
        if accelerationMagnitude > maxAcceleration {
            let factor = accelerationMagnitude / accelerationMagnitude
            accelerationX *= factor
            accelerationY *= factor
        }
        
        currentVelocity.dx += accelerationX
        currentVelocity.dy += accelerationY
        
        position.x += currentVelocity.dx
        position.y += currentVelocity.dy
        
        let desiredScaleSpeed = (desiredScale - xScale) * 0.2
        var scaleAcceleration = (desiredScaleSpeed - currentScaleSpeed)
        
        if abs(scaleAcceleration) > maxScaleAcceleration {
            scaleAcceleration = copysign(maxAcceleration, scaleAcceleration)
        }
        
        currentScaleSpeed += scaleAcceleration
        
        let newScale = xScale + currentScaleSpeed
    
        xScale = newScale
        yScale = newScale
    }
    
    public func pan(showing sceneFrame: CGRect, withMainFocus focus: CGRect, in cameraFrame: CGRect, landscape: Bool) {
    
        zRotation = landscape ? .pi / 2.0 : 0.0
    
        let adjustedCameraFrame: CGRect
        if landscape {
            // Rotate the frame 90 degrees.
            adjustedCameraFrame = CGRect(x: -cameraFrame.maxY, y: cameraFrame.minX, width: cameraFrame.height, height: cameraFrame.width)
        } else {
            adjustedCameraFrame = cameraFrame
        }
        
        let minXScale = (sceneFrame.width) / adjustedCameraFrame.width
        let minYScale = (sceneFrame.height) / adjustedCameraFrame.height
        
        var scale = max(minXScale, minYScale)
        
        if scale < 1.0 {
            scale = 1.0
        }
        
        if scale > 2.0 {
            scale = 2.0
        }
        
        var center = CGPoint(
            x: sceneFrame.midX - adjustedCameraFrame.midX * scale,
            y: sceneFrame.midY - adjustedCameraFrame.midY * scale
        )
        
        if center.y < focus.maxY - adjustedCameraFrame.maxY * scale {
            center.y = focus.maxY - adjustedCameraFrame.maxY * scale
        }
        
        if center.y > focus.minY - adjustedCameraFrame.minY * scale {
            center.y = focus.minY - adjustedCameraFrame.minY * scale
        }
        
        if center.x < focus.maxX - adjustedCameraFrame.maxX * scale {
            center.x = focus.maxX - adjustedCameraFrame.maxX * scale
        }
        
        if center.x > focus.minX - adjustedCameraFrame.minX * scale {
            center.x = focus.minX - adjustedCameraFrame.minX * scale
        }
        
        panTowards(desiredPosition: center, desiredScale: scale)
    }
    
    public func cut() {
        shouldCutNextMovement = true
    }
    
    private func cutTo(position: CGPoint, scale: CGFloat) {
        currentVelocity = .zero
        currentScaleSpeed = 0.0
        self.position = position
        self.xScale = scale
        self.yScale = scale
    }
}
