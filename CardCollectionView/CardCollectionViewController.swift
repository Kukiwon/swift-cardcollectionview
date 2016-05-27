//
//  CardCollectionViewController.swift
//  CardCollectionView
//
//  Created by Jordy van Kuijk on 27/05/16.
//  Copyright © 2016 Skopei. All rights reserved.
//

import UIKit

class CardCollectionViewController: UIViewController {

    @IBOutlet var collectionView: UIView!
    
    // The amount of offset for each card view
    let incrementY:CGFloat = 8
    // The scale factor in the x direction
    let scaleX: CGFloat = 0.01
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add cards to the collection view
        addPanGestureRecognizerForCardView(addCard(atIndex: nil)!)
        addCard(atIndex: nil)
        addCard(atIndex: nil)
        
        animate()
    }

    /** Instantiates a new Card View and draws its layer, adds constraints and adds it to the collecton view */
    func addCard(atIndex index: Int?, animated: Bool = false) -> CardView? {
        // Instantiate a new Card View
        guard let cardView = UINib(nibName: "CardView", bundle: nil).instantiateWithOwner(nil, options: nil).first as? CardView else { return nil }
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let cardIndex = index ?? collectionView.subviews.count
        cardView.setupUI(forIndex: cardIndex)
        
        if animated {
            cardView.layer.opacity = 0
            var t = initialTransformForCardViewAtIndex(2)
            t = CATransform3DTranslate(t, 0, incrementY, 0)
            cardView.layer.transform = t
            animateLayerToTransform(cardView.layer, transform: initialTransformForCardViewAtIndex(2))
            cardView.layer.opacity = 1
            cardView.layer.transform = initialTransformForCardViewAtIndex(2)
        }
        
        // Add the card to the collection view
        collectionView.insertSubview(cardView, atIndex: 0)
        
        // Setup constraints
        let margins = collectionView.layoutMarginsGuide
        cardView.leadingAnchor.constraintEqualToAnchor(margins.leadingAnchor, constant: 0).active = true
        cardView.rightAnchor.constraintEqualToAnchor(margins.rightAnchor, constant: 0).active = true
        cardView.topAnchor.constraintEqualToAnchor(margins.topAnchor, constant: 0).active = true
        cardView.bottomAnchor.constraintEqualToAnchor(margins.bottomAnchor, constant: -8).active = true
        
        return cardView
    }
    
    /** Adds a pan gesture recognizer to the supplied card view */
    func addPanGestureRecognizerForCardView(cardView: CardView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(panGestureRecognizer)
    }
    
    /** Sets the correct transform for each layer of the cards **/
    func animate() {
        // For each card view, apply a translation and a scale
        for (index, subview) in collectionView.subviews.reverse().enumerate() {
            subview.layer.transform = initialTransformForCardViewAtIndex(index)
        }
    }
    
    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        guard let cardView = gestureRecognizer.view as? CardView else { return }
        
        switch gestureRecognizer.state {
        case .Began, .Changed:
            
            // Animate the target card view over the x axis
            var t = CATransform3DIdentity
            let dX = gestureRecognizer.translationInView(cardView).x
            t = CATransform3DTranslate(t, dX, 0, 0)
            cardView.layer.transform = t
            
            // Animate the other card views underneath
            let percentage = dX / cardView.bounds.width
            for (index, subView) in collectionView.subviews.reverse().enumerate() {
                guard subView != cardView else { continue }
                var t = initialTransformForCardViewAtIndex(index)
                t = CATransform3DTranslate(t, 0, -(incrementY * abs(percentage)), 0)
                subView.layer.transform = t
            }
            
        case .Ended:
            
            // Calculate the percentage that the view has been swiped and animate the card views based on how far the user swiped.
            let dX = gestureRecognizer.translationInView(cardView).x
            let percentage = dX / cardView.bounds.width
            
            if percentage > 0.5 {
                // Toss away the current card view, present the next one
                segueToNextCardView(fromCurrentCardView: cardView)
            } else {
                // Transition cards back to their initial position
                for (index, subView) in collectionView.subviews.reverse().enumerate() {
                    let t = initialTransformForCardViewAtIndex(index)
                    animateLayerToTransform(subView.layer, transform: t)
                    subView.layer.transform = t
                }
            }
        default: break
        }
    }
    
    /**
     Given a layer and a transformation, animated the layer from the current transform to the specified one.
    */
    func animateLayerToTransform(layer: CALayer, transform: CATransform3D, timingFunctionName: String = kCAMediaTimingFunctionEaseOut, completion: (() -> Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(CATransform3D: layer.transform)
        animation.toValue = NSValue(CATransform3D: transform)
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction.init(name: timingFunctionName)
        layer.addAnimation(animation, forKey: "transform")
        
        if layer.opacity == 0 {
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 0
            opacityAnimation.toValue = 1
            opacityAnimation.duration = 0.2
            layer.addAnimation(opacityAnimation, forKey: "opacity")
        }
        
        CATransaction.commit()
    }
    
    /** 
     - Returns: a tranformation matrix for a cardView at the specified index.
        If the index > 2, returns the identity index.
     */
    func initialTransformForCardViewAtIndex(index: Int) -> CATransform3D {
        guard index < 3 else { return CATransform3DIdentity }
        var t = CATransform3DIdentity
        
        let cGIndex = CGFloat(index)
        let dY: CGFloat = cGIndex * incrementY
        let dX: CGFloat = 0
        
        t = CATransform3DTranslate(t, dX, dY, 0)
        t = CATransform3DScale(t, 1 - (scaleX * cGIndex), 1, 1)
        return t
    }
    
    func segueToNextCardView(fromCurrentCardView cardView: CardView) {
        assert(cardView == collectionView.subviews.last)
        
        // Animate the current card view away from the view (right)
        var t = CATransform3DIdentity
        t = CATransform3DTranslate(t, cardView.bounds.width + 100, 0, 0)
        animateLayerToTransform(cardView.layer, transform: t, timingFunctionName: kCAMediaTimingFunctionEaseOut) {
            cardView.removeFromSuperview()
            
            // Animate remaining views to their now positions
            for (index, cardView) in self.collectionView.subviews.reverse().enumerate() {
                let t = self.initialTransformForCardViewAtIndex(index)
                self.animateLayerToTransform(cardView.layer, transform: t)
                cardView.layer.transform = t
            }
            
            self.addCard(atIndex: cardView.index, animated: true)
            let lastCard = self.collectionView.subviews.last as! CardView
            self.addPanGestureRecognizerForCardView(lastCard)
        }
        cardView.layer.transform = t
        
    }
}
