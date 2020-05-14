//
//  SensorDisplayView.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-31.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(SensorDisplayView)
@IBDesignable
public class SensorDisplayView: UIView {
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var leadingSensorValueConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingSensorValueConstraint: NSLayoutConstraint!
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var sensorValueLabel: UILabel!
    @IBOutlet private weak var pillView: UIView!
    @IBOutlet private weak var pillViewWidthMinimumWidthConstraint: NSLayoutConstraint!
        
    public enum SensorViewOrientiation: Int {
        case vertical = 0
        case horizontal = 1
    }
    
    public enum SensorDisplayViewSize: CGFloat {
        case compact = 10.0
        case expanded = 30.0
    }
    
    private struct ConfigurationOptions {
        var font: UIFont
        var stackViewSpacing: CGFloat
        var stackViewAxis: UILayoutConstraintAxis
        var indexOfTitle: Int

        static var horizontalConfiguration: ConfigurationOptions {
            get {
                return ConfigurationOptions(font: UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold), stackViewSpacing: 10.0, stackViewAxis: .horizontal, indexOfTitle: 0)
            }
        }
        
        static var verticalConfiguration: ConfigurationOptions {
            get {
                return ConfigurationOptions(font: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightSemibold), stackViewSpacing: 5.0, stackViewAxis: .vertical, indexOfTitle: 1)
            }
        }
    }
    
    
    public var orientation: SensorViewOrientiation = .horizontal {
        didSet {
            stackView.removeArrangedSubview(titleLabel)
            var configuration: ConfigurationOptions = .horizontalConfiguration
            switch orientation {
            case .horizontal:
                configuration = .horizontalConfiguration
            case .vertical:
                configuration = .verticalConfiguration
            }
            
            stackView.insertArrangedSubview(titleLabel, at: configuration.indexOfTitle)
            stackView.axis = configuration.stackViewAxis
            stackView.spacing = configuration.stackViewSpacing
            titleLabel.font = configuration.font
        }
    }
    
    #if TARGET_INTERFACE_BUILDER
    @IBInspectable var orientationIB: Int {
        get {
            return orientation.rawValue
        }
        set {
            guard let orientation = SensorViewOrientiation(rawValue: newValue) else { return }
            self.orientation = orientation
        }
    }   //convenience var, enum not inspectable
    #endif
    
    @IBInspectable var titleText: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }
    
    @IBInspectable var minimumPillWidth: CGFloat {
        get {
            return pillViewWidthMinimumWidthConstraint.constant
        }
        
        set {
            pillViewWidthMinimumWidthConstraint.constant = newValue
            setNeedsLayout()
        }
    }
    
    public var preferredSize: SensorDisplayViewSize = .expanded {
        didSet {
            leadingSensorValueConstraint.constant = preferredSize.rawValue
            trailingSensorValueConstraint.constant = preferredSize.rawValue
            
            if orientation == .vertical {
                sensorValueLabel.preferredMaxLayoutWidth = pillView.bounds.size.width
            }
        }
    }
    
    public func flashColor(_ color: UIColor, forDuration seconds: Double) {
        UIView.transition(with: self, duration: 0.3, options: [], animations: { 
            self.pillView.backgroundColor = color
        }, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) { 
            UIView.transition(with: self, duration: 0.3, options: [], animations: {
                self.pillView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }, completion: nil)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        pillView.layer.cornerRadius = 13.0
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        xibSetup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        xibSetup()
    }
    
    var view: UIView!
    func xibSetup() {
        guard let loadedView = loadViewFromNib() else {
            fatalError("Couldn't load sensor view nib!")
        }
        
        view = loadedView
        
        view.frame = bounds
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
        
        accessibilityTraits = UIAccessibilityTraitUpdatesFrequently
        
        stackView.distribution = .fill
        
        titleLabel.setContentHuggingPriority(1000, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(1000, for: .horizontal)
    }
    
    func loadViewFromNib() -> UIView? {
        
        let bundle = Bundle(for: SensorDisplayView.self)
        let nib = UINib(nibName: "SensorDisplayView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: [:]).first
        
        return view as? UIView
    }
}
