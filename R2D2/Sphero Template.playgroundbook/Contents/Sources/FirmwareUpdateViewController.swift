//
//  FirmwareUpdateViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-24.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(FirmwareUpdateViewController)
public class FirmwareUpdateViewController: ModalViewController {
    @IBOutlet weak var safeContainer: UIView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var spheroImageContainer: UIView!
    @IBOutlet weak var bodyUpdateLabel: UILabel!
    @IBOutlet weak var moreInformationLabel: UILabel!
    @IBOutlet weak var bigSpheroImage: UIImageView!
    @IBOutlet weak var hintArrow: UIImageView!
    @IBOutlet weak var topArrowConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingArrowConstraint: NSLayoutConstraint!
    
    private var topSafeAreaConstraint: NSLayoutConstraint?
    private var bottomSafeAreaConstraint: NSLayoutConstraint?
    
    public var topGradientColor: UIColor?
    public var bottomGradientColor: UIColor?
    
    public var connectedToy: Toy? {
        didSet {
            updateViews()
        }
    }
    
    private func hasVerticalSpace() -> Bool {
        return view.bounds.size.height > 600.0
    }
    
    private func isVeryCompact() -> Bool {
        return (view.bounds.size.width < 400.0 && view.bounds.size.height <= 512.0)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        view.setNeedsUpdateConstraints()
    }
    
    public override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
        setGradientBackground()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let topSafeConstraint = safeContainer.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor, constant: insetLayoutGuide?.layoutFrame.minY ?? 0.0)
        let bottomSafeConstraint = safeContainer.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor, constant: -(view.bounds.size.height - (insetLayoutGuide?.layoutFrame.maxY ?? 0.0)))
        
        topSafeAreaConstraint = topSafeConstraint
        bottomSafeAreaConstraint = bottomSafeConstraint
        
        NSLayoutConstraint.activate([
            topSafeConstraint,
            bottomSafeConstraint
            ])
        
        moreInformationLabel.text = NSLocalizedString("firmware.moreInfoLabel.text", value: "Tap for more information", comment: "instructions for firmware update")
    }
    
    public override func animateIn(callback: @escaping (Bool) -> Void) {
        view.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: { 
            self.view.alpha = 1.0
        }) { (completed) in
            callback(completed)
        }
    }
    
    public override func animateOut(callback: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0.0
        }) { (completed) in
            callback(completed)
        }
    }
    
    public override func updateViewConstraints() {
        if isVeryCompact() {
            stackView.axis = .horizontal
            spheroImageContainer.isHidden = true
            hintArrow.isHidden = true
            view.setNeedsUpdateConstraints()
        } else if view.bounds.size.width < 512.0 && view.bounds.size.height < 512.0 {
            spheroImageContainer.isHidden = false
            hintArrow.isHidden = false
            stackView.axis = .horizontal
            
            view.setNeedsUpdateConstraints()
        } else {
            //normal
            topArrowConstraint.constant = hasVerticalSpace() ? 60.0 : 80.0
            trailingArrowConstraint.constant = hasVerticalSpace() ? 50.0 : 70.0
            
            spheroImageContainer.isHidden = false
            hintArrow.isHidden = false
            
            stackView.axis = hasVerticalSpace() ? .vertical : .horizontal
            
            view.setNeedsUpdateConstraints()
        }
        
        let topSpacing, bottomSpacing: CGFloat
        if let safeAreaFrame = insetLayoutGuide?.layoutFrame {
            topSpacing = safeAreaFrame.minY == 0.0 ? 40.0 : safeAreaFrame.minY
            bottomSpacing = -(view.bounds.size.height - safeAreaFrame.maxY)
        } else {
            topSpacing = 0.0
            bottomSpacing = 0.0
        }
        
        if let topSafeConstraint = topSafeAreaConstraint, let bottomSafeConstraint = bottomSafeAreaConstraint {
            topSafeConstraint.constant = topSpacing
            bottomSafeConstraint.constant = bottomSpacing
            
            view.setNeedsUpdateConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func updateViews() {
        let bodyText: String
        
        switch connectedToy {
        case _ as BB8Toy:
            view.accessibilityLabel = NSLocalizedString("firmwareUpdate.image.bb8Accessibility", value: "BB-8 robot needs an update. Arrow pointing to the top right of the screen indicating where to tap.", comment: "accessibility for BB-8 firmware update")
            bodyText = NSLocalizedString("firmwareUpdate.bodyLabel.bb8Text", value: "BB-8 needs an update", comment: "firmware update. toy needs an update")
            bigSpheroImage.image = #imageLiteral(resourceName: "bb8")

        case _ as SPRKToy:
            view.accessibilityLabel = NSLocalizedString("firmwareUpdate.image.sprkAccessibility", value: "Sad Sphero robot with a droopy antenna. Robot requires an update. Arrow pointing to the top right of the screen indicating where to tap.", comment: "accessibility for sprk+ firmware update")
            bodyText = NSLocalizedString("firmwareUpdate.bodyLabel.sprkText", value: "SPRK+ needs an update", comment: "firmware update. toy needs an update")
            bigSpheroImage.image = #imageLiteral(resourceName: "firmware-update-toy")

        case _ as R2D2Toy:
            view.accessibilityLabel = NSLocalizedString("firmwareUpdate.image.r2Accessibility", value: "R2D2 robot needs an update. Arrow pointing to the top right of the screen indicating where to tap.", comment: "accessibility for r2d2 firmware update")
            bodyText = NSLocalizedString("firmwareUpdate.bodyLabel.r2Text", value: "R2-D2 needs an update", comment: "firmware update. toy needs an update")
            bigSpheroImage.image = #imageLiteral(resourceName: "r2D2Front")
            
        case _ as BB9EToy:
            view.accessibilityLabel = NSLocalizedString("firmwareUpdate.image.bb9eAccessibility", value: "BB9E robot needs an update. Arrow pointing to the top right of the screen indicating where to tap.", comment: "accessibility for bb9e firmware update")
            bodyText = NSLocalizedString("firmwareUpdate.bodyLabel.bb9eText", value: "BB-9E needs an update", comment: "firmware update. toy needs an update")
            bigSpheroImage.image = #imageLiteral(resourceName: "bb9e")
            
        case _ as BoltToy:
            view.accessibilityLabel = NSLocalizedString("firmwareUpdate.image.sprkAccessibility", value: "Sad Sphero robot with a droopy antenna. Robot requires an update. Arrow pointing to the top right of the screen indicating where to tap.", comment: "accessibility for sprk+ firmware update")
            bodyText = NSLocalizedString("firmwareUpdate.bodyLabel.boltText", value: "BOLT needs an update", comment: "firmware update. toy needs an update")
            bigSpheroImage.image = #imageLiteral(resourceName: "firmware-update-toy")
            
        case _ as MiniToy:
            view.accessibilityLabel = NSLocalizedString("firmwareUpdate.image.sprkAccessibility", value: "Sad Sphero robot with a droopy antenna. Robot requires an update. Arrow pointing to the top right of the screen indicating where to tap.", comment: "accessibility for sprk+ firmware update")
            bodyText = NSLocalizedString("firmwareUpdate.bodyLabel.miniText", value: "Mini needs an update", comment: "firmware update. toy needs an update")
            bigSpheroImage.image = #imageLiteral(resourceName: "firmware-update-toy")
            
        default:
            bodyText = ""

        }
        
        bodyUpdateLabel.text = bodyText.uppercased()
    }
    
    static public func instantiate(with toy: Toy?) -> FirmwareUpdateViewController {
        let firmwareUpdateViewController: FirmwareUpdateViewController = FirmwareUpdateViewController.instantiateFromStoryboard()
        firmwareUpdateViewController.connectedToy = toy
        return firmwareUpdateViewController
    }
    
    private func setGradientBackground() {
        guard let colorTop = topGradientColor?.cgColor, let colorBottom = bottomGradientColor?.cgColor else {
            view.backgroundColor = UIColor(red: 54.0/255.0, green: 129.0/255.0, blue: 249.0/255.0, alpha: 1.0)
            
            return
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
}
