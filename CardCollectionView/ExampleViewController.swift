//
//  ExampleViewController.swift
//  CardCollectionView
//
//  Created by Jordy van Kuijk on 27/05/16.
//  Copyright © 2016 Skopei. All rights reserved.
//

import UIKit

class ExampleViewController: UIViewController, CardCollectionViewDataSource {
    
    @IBOutlet var cardCollectionView: CardCollectionView!
    var cards: [CardView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        for i in 0...2 {
            let card = UINib(nibName: "CardView", bundle: nil).instantiateWithOwner(nil, options: nil).first as! CardView
            card.setupUI(forIndex: i)
            cards.append(card)
        }
        
        cardCollectionView.dataSource = self
    }
    
    func numberOfCardsForCollectionView(cardCollectionView: CardCollectionView) -> Int {
        return cards.count
    }
    
    func cardAtIndexForCollectionView(cardCollectionView: CardCollectionView, index: Int) -> CardView {
        return cards[index]
    }
}

