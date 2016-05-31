//
//  CardCollectionView.swift
//  CardCollectionView
//
//  Created by Jordy van Kuijk on 27/05/16.
//  Copyright © 2016 Skopei. All rights reserved.
//

import UIKit

protocol CardCollectionViewDataSource {
    func numberOfCardsForCollectionView(cardCollectionView: CardCollectionView) -> Int
    func cardAtIndexForCollectionView(cardCollectionView: CardCollectionView, index: Int) -> CardView
}

internal enum CardViewTransition {
    case InFromBottom
    case InFromRight
    case InFromLeft
    case InFromTop
    case Out
    case OutRight
}

class CardCollectionView: UIView {
    
    // Datasource
    var dataSource: CardCollectionViewDataSource? {
        didSet {
            setupCards()
        }
    }
    
    // The amount of offset for each card view
    let incrementY:CGFloat = 8
    // The scale factor in the x direction
    let scaleX: CGFloat = 0.01
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func setupCards() {
        guard let dataSource = dataSource else { return }
        for i in 0 ..< dataSource.numberOfCardsForCollectionView(self) {
            let card = dataSource.cardAtIndexForCollectionView(self, index: i)
            addCard(card, atIndex: i)
        }
        
        let topCard = dataSource.cardAtIndexForCollectionView(self, index: 0)
        addPanGestureRecognizerForCardView(topCard)
        
        animate()
    }
    
    /** Instantiates a new Card View and draws its layer, adds constraints and adds it to the collecton view */
    func addCard(cardView: CardView, atIndex index: Int?, animated: Bool = false) -> CardView? {
        
        cardView.gestureRecognizers?.removeAll()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.index = index ?? 0
    
        if animated {
            transitionCardView(cardView, transition: .InFromBottom)
        }
        
        // Add the card to the collection view
        insertSubview(cardView, atIndex: 0)
        
        // Setup constraints
        let margins = layoutMarginsGuide
        cardView.leadingAnchor.constraintEqualToAnchor(margins.leadingAnchor, constant: 0).active = true
        cardView.rightAnchor.constraintEqualToAnchor(margins.rightAnchor, constant: 0).active = true
        cardView.topAnchor.constraintEqualToAnchor(margins.topAnchor, constant: 0).active = true
        cardView.bottomAnchor.constraintEqualToAnchor(margins.bottomAnchor, constant: 0).active = true
        
        return cardView
    }
    
    /** Adds a pan gesture recognizer to the supplied card view */
    func addPanGestureRecognizerForCardView(cardView: CardView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        cardView.addGestureRecognizer(panGestureRecognizer)
    }
    
    /** Sets the correct transform for each layer of the cards **/
    func animate() {
        // For each card view, apply a translation and a scale
        for (index, subview) in subviews.reverse().enumerate() {
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
            var percentage = dX / cardView.bounds.width
            for (index, subView) in subviews.reverse().enumerate() {
                guard subView != cardView else { continue }
                var t = initialTransformForCardViewAtIndex(index)
                percentage = abs(percentage)
                percentage *= 2
                percentage /= CGFloat(index)
                percentage = min(1, percentage)
                let decrement = -(incrementY * percentage)
                t = CATransform3DTranslate(t, 0, decrement, 0)
                subView.layer.transform = t
            }
            
        case .Ended, .Cancelled, .Failed:
            // Calculate the percentage that the view has been swiped and animate the card views based on how far the user swiped.
            let dX = gestureRecognizer.translationInView(cardView).x
            let percentage = dX / cardView.bounds.width
            
            if percentage > 0.35 {
                // Toss away the current card view, present the next one
                segueToNextCardView(fromCurrentCardView: cardView)
            } else {
                // Transition cards back to their initial position
                for (index, subView) in subviews.reverse().enumerate() {
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
        animation.duration = 1
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
        layer.transform = transform
    }
    
    /**
     - Returns: a tranformation matrix for a cardView at the specified index.
     If the index > 2, returns the identity index.
     */
    func initialTransformForCardViewAtIndex(index: Int) -> CATransform3D {
        var t = CATransform3DIdentity
        
        let cGIndex = CGFloat(index)
        let dY: CGFloat = cGIndex * incrementY
        let dX: CGFloat = 0
        
        t = CATransform3DTranslate(t, dX, dY, 0)
        t = CATransform3DScale(t, 1 - (scaleX * cGIndex), 1, 1)
        return t
    }
    
    func segueCard(fromIndex fromIndex: Int, toIndex: Int) {
        // Ensure that there is a datasource set
        guard let dataSource = dataSource else {
            fatalError("Card collection view has no data source.")
        }
        
        // Ensure that the index is within bounds
        guard fromIndex >= 0 && fromIndex < dataSource.numberOfCardsForCollectionView(self) else {
            fatalError("fromIndex out of bounds!")
        }
        
        // Ensure that the index is within bounds
        guard toIndex >= 0 && toIndex < dataSource.numberOfCardsForCollectionView(self) else {
            fatalError("toIndex out of bounds!")
        }
        
        // First segue out the destination card view
        let fromCardView = dataSource.cardAtIndexForCollectionView(self, index: fromIndex)
        transitionCardView(fromCardView, transition: .OutRight) {
            // Transition other cards to their correct position
            for view in self.subviews {
                guard let cardView = view as? CardView where view != fromCardView else { continue }
                if fromCardView.index > cardView.index {
                    cardView.index += 1
                }
                let t = self.initialTransformForCardViewAtIndex(cardView.index)
                self.animateLayerToTransform(cardView.layer, transform: t)
            }
            
            fromCardView.layer.zPosition = CGFloat(self.subviews.count)
            self.transitionCardView(fromCardView, transition: .InFromRight)
        }
    }
    
    func segueToNextCardView(fromCurrentCardView cardView: CardView) {
        guard (cardView == subviews.last) else { return }
        
        // Animate the current card view away from the view (right)
        var t = CATransform3DIdentity
        t = CATransform3DTranslate(t, cardView.bounds.width + 100, 0, 0)
        animateLayerToTransform(cardView.layer, transform: t, timingFunctionName: kCAMediaTimingFunctionEaseOut) {
            cardView.removeFromSuperview()
            
            // Animate remaining views to their now positions
            for (index, cardView) in self.subviews.reverse().enumerate() {
                let t = self.initialTransformForCardViewAtIndex(index)
                self.animateLayerToTransform(cardView.layer, transform: t)
                cardView.layer.transform = t
            }
            
            self.addCard(self.dataSource!.cardAtIndexForCollectionView(self, index: cardView.index), atIndex: cardView.index, animated: true)
            let lastCard = self.subviews.last as! CardView
            self.addPanGestureRecognizerForCardView(lastCard)
        }
        cardView.layer.transform = t
    }
    
    // #warning: - wrong implementation! in transition should end up on top
    func transitionCardView(cardView: CardView, transition: CardViewTransition, onComplete: (Void -> Void)? = nil) {
        switch transition {
        case .InFromBottom:
            let totalAmountOfCards = (dataSource?.numberOfCardsForCollectionView(self) ?? 0) - 1
            cardView.layer.opacity = 0
            var t = initialTransformForCardViewAtIndex(totalAmountOfCards)
            t = CATransform3DTranslate(t, cardView.bounds.size.width + 100 , 0, 0)
            cardView.layer.transform = t
            animateLayerToTransform(cardView.layer, transform: initialTransformForCardViewAtIndex(totalAmountOfCards), timingFunctionName: kCAMediaTimingFunctionEaseOut, completion: onComplete)
            cardView.layer.opacity = 1
            cardView.layer.transform = initialTransformForCardViewAtIndex(totalAmountOfCards)
        case .InFromRight:
            var t = initialTransformForCardViewAtIndex(0)
            cardView.layer.opacity = 0
            t = CATransform3DTranslate(t, cardView.bounds.size.width + 100 , 0, 0)
            cardView.layer.transform = t
            animateLayerToTransform(cardView.layer, transform: initialTransformForCardViewAtIndex(0), timingFunctionName: kCAMediaTimingFunctionEaseOut, completion: onComplete)
            cardView.layer.opacity = 1
        case .Out:
            var t = CATransform3DIdentity
            t = CATransform3DTranslate(t, cardView.bounds.width + 100, 0, 0)
            animateLayerToTransform(cardView.layer, transform: t, timingFunctionName: kCAMediaTimingFunctionEaseOut) {
                
                cardView.removeFromSuperview()
                
                // Animate remaining views to their new positions
                for cV in self.subviews {
                    guard let cV = cV as? CardView where cV != cardView else { continue }
                    let t = self.initialTransformForCardViewAtIndex(cV.index)
                    self.animateLayerToTransform(cV.layer, transform: t)
                    cV.layer.transform = t
                    cV.index -= 1
                }
                
                self.addCard(self.dataSource!.cardAtIndexForCollectionView(self, index: cardView.index), atIndex: cardView.index, animated: true)
                let lastCard = self.subviews.last as! CardView
                self.addPanGestureRecognizerForCardView(lastCard)
                onComplete?()
            }
            cardView.layer.transform = t
        case .OutRight:
            var t = initialTransformForCardViewAtIndex(cardView.index)
            t = CATransform3DTranslate(t, cardView.bounds.width + 100, 0, 0)
            animateLayerToTransform(cardView.layer, transform: t, timingFunctionName: kCAMediaTimingFunctionEaseOut, completion: onComplete)
        default: break
        }
    }
    
    func selectCardAtIndex(index: Int) {
        
        // Ensure that there is a datasource set
        guard let dataSource = dataSource else {
            fatalError("Card collection view has no data source.")
        }
        
        // Ensure that the index is within bounds
        guard index > 0 && index < dataSource.numberOfCardsForCollectionView(self) else {
            fatalError("Index out of bounds!")
        }
        
        // Ensure that the card view is not equal to the current card
        guard let currentCard = subviews.last as? CardView where currentCard.index != index else {
            return
        }
        
        
        let card = dataSource.cardAtIndexForCollectionView(self, index: index)
        segueCard(fromIndex: card.index, toIndex: 0)
        
//        if let lastCard = self.subviews.last as? CardView {
//            transitionCardView(lastCard, transition: .Out) {
//                self.transitionCardView(card, transition: .Out) {
//                    self.addCard(card, atIndex: dataSource.numberOfCardsForCollectionView(self) - 1)
//                    let lastCard = self.subviews.last as! CardView
//                    self.addPanGestureRecognizerForCardView(lastCard)
//                }
//            }
//        }
    }
}
