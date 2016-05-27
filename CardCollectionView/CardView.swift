//
//  CardView.swift
//  CardCollectionView
//
//  Created by Jordy van Kuijk on 27/05/16.
//  Copyright © 2016 Skopei. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    @IBOutlet var label: UILabel!
    
    var index: Int = 0
    
    override internal class func layerClass() -> AnyClass {
        return CAGradientLayer.classForCoder()
    }
    
    func setupUI(forIndex index: Int = 0) {
        guard let layer = layer as? CAGradientLayer else { return }
        layer.anchorPoint = CGPointMake(0.5, 0.5)
        layer.cornerRadius = 4.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.3).CGColor
        layer.borderWidth = 2
        layer.colors = getColorsForLayer(atIndex: index)
        layer.locations = [0, 1]
//        layer.shadowColor = UIColor(white: 0.6, alpha: 1).CGColor
//        layer.shadowOpacity = 0.1
//        layer.shadowRadius = 2
//        layer.shadowPath = UIBezierPath(roundedRect: layer.frame, cornerRadius: 4.0).CGPath
        
        // Set up label
        label.text = "Card \(index + 1)"
        self.index = index
    }
    
    /**
     - Parameter index: based on the index, a different array of colors will be returned.
     - Returns: an array of colors for a gradient CA Layer
     */
    func getColorsForLayer(atIndex index: Int) -> [CGColor] {
        switch index {
        case 1:
            return [getRandomColor().CGColor, getRandomColor().CGColor]
        case 2:
            return [getRandomColor().CGColor, getRandomColor().CGColor]
        default: return [getRandomColor().CGColor, getRandomColor().CGColor]
        }
    }
    
    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}
