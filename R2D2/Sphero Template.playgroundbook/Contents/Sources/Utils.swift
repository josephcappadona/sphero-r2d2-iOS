//
//  Utils.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-20.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    
    public static func instantiateFromStoryboard<T>() -> T {
        let bundle = Bundle(for: T.self as! AnyClass)
        let storyboard = UIStoryboard(name: "DeathStar", bundle: bundle)
        let identifier = String(describing: self)
        
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
    
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined(separator: "-")
    }
    
}

extension UIView {
    public func pinEdges(to view: UIView) {
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
    }
    
    public func pinEdges(toGuide guide: UILayoutGuide) {
        NSLayoutConstraint.activate([
            guide.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            guide.topAnchor.constraint(equalTo: self.topAnchor),
            guide.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            guide.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
    }
    
}

extension UIFont {
    
    public static let arcadeFontName: String = {
        let fontUrl = Bundle.main.url(forResource: "slkscr", withExtension: "ttf")!
        CTFontManagerRegisterFontsForURL(fontUrl as CFURL, CTFontManagerScope.process, nil)
        return "Silkscreen"
    }()
    
    public class func arcadeFont(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont(name: arcadeFontName, size: 25.0)!
    }
    
}

private let angleDescriptions: [(Double,String)] = [
    (0.0,    NSLocalizedString("SpheroSimulator_AngleDescription_Forward",     value: "Forward",      comment: "VoiceOver description for Sphero heading Forward")),
    (45.0,   NSLocalizedString("SpheroSimulator_AngleDescription_ForwardRight", value: "Forward Right", comment: "VoiceOver description for Sphero heading Forward Right")),
    (90.0,   NSLocalizedString("SpheroSimulator_AngleDescription_Right",      value: "Right",       comment: "VoiceOver description for Sphero heading Right")),
    (135.0,  NSLocalizedString("SpheroSimulator_AngleDescription_BackwardRight", value: "Backward Right", comment: "VoiceOver description for Sphero heading Backward Right")),
    (180.0,  NSLocalizedString("SpheroSimulator_AngleDescription_Backward",     value: "Backward",      comment: "VoiceOver description for Sphero heading Backward")),
    (-135.0, NSLocalizedString("SpheroSimulator_AngleDescription_BackwardLeft", value: "Backward Left", comment: "VoiceOver description for Sphero heading Backward Left")),
    (-90.0,  NSLocalizedString("SpheroSimulator_AngleDescription_Left",      value: "Left",       comment: "VoiceOver description for Sphero heading Left")),
    (-45.0,  NSLocalizedString("SpheroSimulator_AngleDescription_ForwardLeft", value: "Forward Left", comment: "VoiceOver description for Sphero heading Forward Left"))
]

extension Double {

    public func angleDescription() -> String {
        var bestDescription = ""
        var minAngleDistance = 360.0
        
        for (angle, description) in angleDescriptions {
            let distance = abs((angle - self).canonizedAngle())
            
            if distance < minAngleDistance {
                minAngleDistance = distance
                bestDescription = description
            }
        }
        
        return bestDescription
    }
    
}

extension Array {
    
    mutating func shuffle() {
        for i in stride(from: count - 1, through: 1, by: -1) {
            let j = Int(arc4random_uniform(UInt32(i+1)))
            
            (self[i],self[j]) = (self[j],self[i])
        }
    }
}

extension UIBezierPath {
    public func bolt(to toPoint: CGPoint, smoothness: CGFloat = 10.0) {
        let fromPoint = currentPoint
        let distance = hypot(toPoint.y - fromPoint.y, toPoint.x - fromPoint.x)
        
        if distance < smoothness {
            addLine(to: toPoint)
            return
        }
        
        var midX = (fromPoint.x + toPoint.x) / 2
        var midY = (fromPoint.y + toPoint.y) / 2
        
        midX += CGFloat(Double.random() - 0.5) * distance / 3.0
        midY += CGFloat(Double.random() - 0.5) * distance / 3.0
        
        bolt(to: CGPoint(x: midX, y: midY))
        bolt(to: toPoint)
    }
}
