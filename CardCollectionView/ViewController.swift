//
//  ViewController.swift
//  CardCollectionView
//
//  Created by Jordy van Kuijk on 27/05/16.
//  Copyright © 2016 Skopei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let transformLayer = CATransformLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init the tranform layer
        view.layer.addSublayer(transformLayer)
        
        // Create 3 cards
        addCard()
        addCard()
        addCard()
        
        animate()
        
        print("view did load")
    }


    /** Adds a card to the transform layer. */
    func addCard() {
        
        let layer = CAGradientLayer()
        layer.frame = CGRectInset(view.bounds, 16, view.bounds.size.height * 0.38)
        layer.anchorPoint = CGPointMake(0.5, 0.5)
        layer.cornerRadius = 4.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.3).CGColor
        layer.borderWidth = 4
        layer.colors = getColorsForLayer(atIndex: transformLayer.sublayers?.count ?? 0)
        layer.locations = [0, 1]
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 20
        
        transformLayer.addSublayer(layer)
    }
    
    func getColorsForLayer(atIndex index: Int) -> [CGColor] {
        switch index {
        case 1:
            return [UIColor.blueColor().CGColor, UIColor.yellowColor().CGColor]
        case 2:
            return [UIColor.greenColor().CGColor, UIColor.orangeColor().CGColor]
        default: return [UIColor.purpleColor().CGColor, UIColor.redColor().CGColor]
        }
    }
    
    /** Performs the tranformation on each card */
    func animate() {
        guard let sublayers = transformLayer.sublayers else { return }
        
        let incrementY:CGFloat = 10
        
        for (index, layer) in sublayers.enumerate() {
            var t = CATransform3DIdentity
            t.m34 = 1 / -1000
            
            let dY: CGFloat = CGFloat(-index) * incrementY
            let dX: CGFloat = 0
            
            t = CATransform3DTranslate(t, dX, dY, 0)
            layer.transform = t
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        transformLayer.frame = self.view.bounds
    }
}
