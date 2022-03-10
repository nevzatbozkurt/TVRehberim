//
//  ViewControllerPannable.swift
//  Alanyaspor
//
//  Created by Nevzat BOZKURT on 28.09.2018.
//  Copyright © 2018 Nevzat BOZKURT. All rights reserved.
//  çekip bırakarak modali kapatmaya sağlıyor..

import UIKit

class ViewControllerPannable: UIViewController {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var currentBGColor: UIColor?
    override func viewDidLoad() {
        super.viewDidLoad()
        currentBGColor = view.backgroundColor
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer!)
    }
    
    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        if panGesture.state == .began {
            originalPosition = view.center
            currentPositionTouched = panGesture.location(in: view)
        } else if panGesture.state == .changed {
            //tutunca
            view.backgroundColor = UIColor(white: 0, alpha: 0) //arka plan rengini temizliyoruz.
            view.frame.origin = CGPoint(
                x: translation.x,
                y: translation.y
            )
        } else if panGesture.state == .ended {
            //kapatınca
            let velocity = panGesture.velocity(in: view)
            if (velocity.y >= 1500) {
                UIView.animate(withDuration: 0.2
                    , animations: {
                        self.view.frame.origin = CGPoint(
                            x: self.view.frame.origin.x,
                            y: self.view.frame.size.height
                        )
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                //bırakınca
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = self.originalPosition!
                    self.view.alpha = 1
                    self.view.backgroundColor = self.currentBGColor
                })
            }
        }
    }
}
