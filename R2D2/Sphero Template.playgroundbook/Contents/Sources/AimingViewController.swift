//
//  AimingViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-21.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit

@objc(AimingViewController)
public class AimingViewController: ModalViewController {
    var callback: ((_ aimingViewController: AimingViewController) -> Void)?
    var toy: Toy?
    
    @IBOutlet weak var dimmingView: UIView!
    @IBOutlet weak var modalView: UIView!
    
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var spheroImageView: UIImageView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        readyButton.layer.cornerRadius = readyButton.bounds.size.height / 2.0
        
        var imageName: String, toyName: String
        switch toy {
        case is BB8Toy:
            imageName = "aiming-bb8"
            toyName = NSLocalizedString("toy.name.bb8", value: "BB-8", comment: "BB-8 robot")
            
        default:
            imageName = "aiming-sphero"
            toyName = NSLocalizedString("toy.name.sphero", value: "Sphero", comment: "Generic Sphero robot")
            
        }
        
        spheroImageView.image = UIImage(named: imageName)
        
        let headerText = String(format: NSLocalizedString("aiming.titleLabel.text", value: "Aim %@", comment: "title label for aiming"), toyName)
        titleLabel.text = headerText.uppercased()
        titleLabel.accessibilityLabel = headerText
        
        let bodyText = NSLocalizedString("aiming.bodyLabel.text", value: "Make sure the blue tail light is facing you!", comment: "body text for aiming, turn Sphero until its small blue taillight is facing the user, \n newline for separating the two strings")
        bodyLabel.text = bodyText
        bodyLabel.accessibilityLabel = bodyText + String(format: NSLocalizedString("aiming.bodyLabel.accessibilityLabel", value: "If you’re having trouble aiming %@, tap ready. Feel which way it rolls. The tail light faces the opposite direction it rolls.", comment: "aiming modal accessibility."), toyName)
        spheroImageView.accessibilityLabel = String(format: NSLocalizedString("aiming.spheroImage.accessibility", value: "Shoes behind a %@, its blue tail light on. Tail light is facing towards the shoes and away from an arrow, indicating the direction it will roll.", comment: "aiming image accessiblity, image shows a small Sphero with a blue tail light facing away from an arrow and towards a pair of shoes"), toyName)
        
        readyButton.setTitle(NSLocalizedString("aiming.readyButton.text", value: "Ready", comment: "button title; finished aiming and ready to run program."), for: .normal)
        readyButton.accessibilityHint = NSLocalizedString("aiming.readyButton.accessibilityHint", value: "Dismisses the aim pop up and starts your code.", comment: "accessibility hint describing what the ready button does.")
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard let insetLayoutGuide = insetLayoutGuide else { return }
        
        let isAstonishinglyCompact = insetLayoutGuide.layoutFrame.size.height < 400.0
        
        // In the storyboard, a priority 500 constraint sets the image view to height 0.
        // Set compression resistance priority to be lower than this when in hella compact mode.
        // This hides the image.
        spheroImageView.setContentCompressionResistancePriority(isAstonishinglyCompact ? 0 : 751, for: UILayoutConstraintAxis.vertical)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        modalView.layer.shadowPath = UIBezierPath(roundedRect: modalView.bounds, cornerRadius: 20.0).cgPath
        modalView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        modalView.layer.shadowColor = UIColor.black.cgColor
        modalView.layer.shadowRadius = 4.0
        modalView.layer.shadowOpacity = 0.5
    }
    
    public override func animateIn(callback: @escaping (Bool) -> Void) {
        dimmingView.alpha = 0.0
        
        UIView.animate(withDuration: 0.4) {
            self.dimmingView.alpha = 1.0
        }
        
        modalView.alpha = 0.0
        modalView.transform = .init(scaleX: 0.01, y: 0.01)
        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 2.0,
                       options: [],
                       animations: {
                        self.modalView.alpha = 1.0
                        self.modalView.transform = .identity
        }) { completed in
            callback(completed)
        }
    }
    
    public override func animateOut(callback: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.4) {
            self.dimmingView.alpha = 0.0
        }
        
        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 2.0,
                       options: [],
                       animations: {
                        self.modalView.alpha = 0.0
                        self.modalView.transform = .init(scaleX: 0.01, y: 0.01)
        }) { completed in
            callback(completed)
        }
    }
    
    static public func instantiate(with toy: Toy?, callback: @escaping (_ aimingViewController: AimingViewController) -> Void) -> AimingViewController {
        let aimingController: AimingViewController = AimingViewController.instantiateFromStoryboard()
        aimingController.callback = callback
        aimingController.toy = toy
        
        return aimingController
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func readyButtonTapped() {
        callback?(self)
    }
}
