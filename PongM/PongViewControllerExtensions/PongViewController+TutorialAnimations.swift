//
//  PongViewControllerTutorialAnimations.swift
//  PongM
//
//  Created by Nikita Stepanov on 14.01.2024.
//

import Foundation
import UIKit

extension PongViewController {
    // MARK: - анимируем туториал
    // конфигурируем вьюху и ее начальное расположение
    func handTutorTutorialConfig() {
        [horizontalArrowImageView,
         horizontalArrowImageViewHolder,
         handTutorImageView
        ].forEach { subView in
            view.addSubview(subView)
            subView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        horizontalArrowImageViewHolder.layer.opacity = 0.3
        
        horizontalArrowImageView.layer.mask = shapeLayer
        
        handTutorImageViewXConstraint = handTutorImageView.centerXAnchor.constraint(equalTo: userPaddleView.centerXAnchor)
        
        NSLayoutConstraint.activate([horizontalArrowImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     horizontalArrowImageView.topAnchor.constraint(equalTo: lineView.topAnchor,
                                                                                      constant: 40),
                                     horizontalArrowImageView.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.8),
                                     horizontalArrowImageView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.2),
                                     
                                     horizontalArrowImageViewHolder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     horizontalArrowImageViewHolder.topAnchor.constraint(equalTo: lineView.topAnchor,
                                                                                      constant: 40),
                                     horizontalArrowImageViewHolder.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.8),
                                     horizontalArrowImageViewHolder.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.2),
                                     
                                     handTutorImageViewXConstraint!,
                                     handTutorImageView.topAnchor.constraint(equalTo: userPaddleView.bottomAnchor,
                                                                             constant: 10),
                                     handTutorImageView.widthAnchor.constraint(equalToConstant: 40),
                                     handTutorImageView.heightAnchor.constraint(equalToConstant: 40)
                                    ])
        self.view.layoutIfNeeded()
        
        animationTimer = Timer.scheduledTimer(timeInterval: 1.65,
                                              target: self,
                                              selector: #selector(handTutorFirstTutorialAnimate),
                                              userInfo: nil,
                                              repeats: true)
        
        animationTimer.fire()
    }
    // непосредственно анимация первого вида
    @objc func handTutorFirstTutorialAnimate() {
        if tutorialState == 0 {
            NSLayoutConstraint.deactivate([handTutorImageViewXConstraint!])
            handTutorImageViewXConstraint = handTutorImageView.centerXAnchor.constraint(equalTo: view.trailingAnchor,
                                                                                        constant: -25)
            NSLayoutConstraint.activate([handTutorImageViewXConstraint!])
            UIView.animate(withDuration: 1.2) {
                self.view.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                NSLayoutConstraint.deactivate([self.handTutorImageViewXConstraint!])
                self.handTutorImageViewXConstraint = self.handTutorImageView.centerXAnchor.constraint(equalTo: self.userPaddleView.centerXAnchor)
                NSLayoutConstraint.activate([self.handTutorImageViewXConstraint!])
                UIView.animate(withDuration: 0.45) {
                    self.view.layoutIfNeeded()
                }
            }
        }
        else if tutorialState == 1 {
            animationTimer.invalidate()
            animationTimer = Timer.scheduledTimer(timeInterval: 1.65,
                                                  target: self,
                                                  selector: #selector(handTutorSecondTutorialAnimate),
                                                  userInfo: nil,
                                                  repeats: true)
            
            animationTimer.fire()
        }
        else {
            removeTutialAnimationH()
        }
    }
    
    @objc func handTutorSecondTutorialAnimate() {
        userPaddleView.frame.origin.x = (view.frame.maxX + view.frame.minX) / 2
        if tutorialState == 1 {
            NSLayoutConstraint.deactivate([handTutorImageViewXConstraint!])
            handTutorImageViewXConstraint = handTutorImageView.centerXAnchor.constraint(equalTo: view.leadingAnchor,
                                                                                        constant: 20)
            NSLayoutConstraint.activate([handTutorImageViewXConstraint!])
            UIView.animate(withDuration: 1.2) {
                self.view.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                NSLayoutConstraint.deactivate([self.handTutorImageViewXConstraint!])
                self.handTutorImageViewXConstraint = self.handTutorImageView.centerXAnchor.constraint(equalTo: self.userPaddleView.centerXAnchor)
                NSLayoutConstraint.activate([self.handTutorImageViewXConstraint!])
                UIView.animate(withDuration: 0.45) {
                    self.view.layoutIfNeeded()
                }
            }
        }
        else {
            removeTutialAnimationH()
            if tutorialState == 2 {
                horizontalArrowImageView.removeFromSuperview()
                horizontalArrowImageViewHolder.removeFromSuperview()
                forcedShotAnimationConfig()
            }
        }
    }
    
    // остновка анимции и удаление с супервью
    func removeTutialAnimationH() {
        animationTimer.invalidate()
        handTutorImageView.removeFromSuperview()
    }
    // MARK: - анимируем второй туториал
    func forcedShotAnimationConfig() {
        [verticalArrowImageView,
         verticalArrowImageViewHolder,
         handTutorImageView
        ].forEach { subView in
            view.addSubview(subView)
            subView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        verticalArrowImageViewHolder.layer.opacity = 0.3
        
        verticalArrowImageView.layer.mask = shapeLayerVertical
        
        handTutorImageViewYConstraint = handTutorImageView.centerYAnchor.constraint(equalTo: userPaddleView.centerYAnchor)
        
        NSLayoutConstraint.activate([verticalArrowImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     verticalArrowImageView.topAnchor.constraint(equalTo: lineView.bottomAnchor,
                                                                                 constant: 30),
                                     verticalArrowImageView.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.5),
                                     verticalArrowImageView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.35),
                                     
                                     verticalArrowImageViewHolder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     verticalArrowImageViewHolder.topAnchor.constraint(equalTo: lineView.bottomAnchor,
                                                                                                              constant: 30),
                                     verticalArrowImageViewHolder.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.5),
                                     verticalArrowImageViewHolder.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.35),
                                     
                                     handTutorImageViewYConstraint!,
                                     
                                     handTutorImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                                                     constant: -20),
                                     handTutorImageView.widthAnchor.constraint(equalToConstant: 40),
                                     handTutorImageView.heightAnchor.constraint(equalToConstant: 40)
                                    ])
        self.view.layoutIfNeeded()
        
        animationTimer.invalidate()
        animationTimer = Timer.scheduledTimer(timeInterval: 1.5,
                                              target: self,
                                              selector: #selector(handTutorThirdTutorialAnimate),
                                              userInfo: nil,
                                              repeats: true)
        
        animationTimer.fire()
    }
    
    @objc func handTutorThirdTutorialAnimate() {
        if tutorialState == 2 {
            NSLayoutConstraint.deactivate([handTutorImageViewYConstraint!])
            handTutorImageViewYConstraint = handTutorImageView.centerYAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                        constant: -30)
            NSLayoutConstraint.activate([handTutorImageViewYConstraint!])
            UIView.animate(withDuration: 0.6) {
                self.view.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                NSLayoutConstraint.deactivate([self.handTutorImageViewYConstraint!])
                self.handTutorImageViewYConstraint = self.handTutorImageView.centerYAnchor.constraint(equalTo: self.lineView.bottomAnchor,
                                                                                                 constant: 30)
                NSLayoutConstraint.activate([self.handTutorImageViewYConstraint!])
                UIView.animate(withDuration: 0.45) {
                    self.view.layoutIfNeeded()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                NSLayoutConstraint.deactivate([self.handTutorImageViewYConstraint!])
                self.handTutorImageViewYConstraint = self.handTutorImageView.centerYAnchor.constraint(equalTo: self.userPaddleView.centerYAnchor)
                NSLayoutConstraint.activate([self.handTutorImageViewYConstraint!])
                UIView.animate(withDuration: 0.45) {
                    self.view.layoutIfNeeded()
                }
            }
        }
        else {
            endTutorial()
        }
    }
    func endTutorial() {
        animationTimer.invalidate()
        tutorialState = 3
        verticalArrowImageView.removeFromSuperview()
        verticalArrowImageViewHolder.removeFromSuperview()
        handTutorImageView.removeFromSuperview()
        needTutorial = false
    }
}
