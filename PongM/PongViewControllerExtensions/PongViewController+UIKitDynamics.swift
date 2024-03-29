//
//  PongViewController+UIKitDynamics.swift
//  Pong
//
//  Created by Timofey on 17.05.2022.
//

import UIKit

extension PongViewController {
    
    // MARK: - UIKitDynamics
    
    /// Эта функция настраивает динамику взаимодействия элементов
    func enableDynamics() {
        // NOTE: Даем мячу, платформе игрока и платформе соперника специальный тэг для идентификации
        ballView.tag = Constants.ballTag
        userPaddleView.tag = Constants.userPaddleTag
        enemyPaddleView.tag = Constants.enemyPaddleTag
        
        let dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
        self.dynamicAnimator = dynamicAnimator
        
        let collisionBehavior = UICollisionBehavior(items: [ballView,
                                                            enemyPaddleView,
                                                            userPaddleView])
        collisionBehavior.collisionDelegate = self
        collisionBehavior.collisionMode = .everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.collisionBehavior = collisionBehavior
        dynamicAnimator.addBehavior(collisionBehavior)
        
        let ballDynamicBehavior = UIDynamicItemBehavior(items: [ballView])
        ballDynamicBehavior.allowsRotation = false
        ballDynamicBehavior.elasticity = 1.0
        ballDynamicBehavior.friction = 0.0
        ballDynamicBehavior.resistance = 0.0
        self.ballDynamicBehavior = ballDynamicBehavior
        dynamicAnimator.addBehavior(ballDynamicBehavior)
        
        let userPaddleDynamicBehavior = UIDynamicItemBehavior(items: [userPaddleView])
        userPaddleDynamicBehavior.allowsRotation = false
        userPaddleDynamicBehavior.density = 10000000
        self.userPaddleDynamicBehavior = userPaddleDynamicBehavior
        dynamicAnimator.addBehavior(userPaddleDynamicBehavior)
        
        let enemyPaddleDynamicBehavior = UIDynamicItemBehavior(items: [enemyPaddleView])
        enemyPaddleDynamicBehavior.allowsRotation = false
        enemyPaddleDynamicBehavior.density = 10000000
        self.enemyPaddleDynamicBehavior = enemyPaddleDynamicBehavior
        dynamicAnimator.addBehavior(enemyPaddleDynamicBehavior)
        
        let attachmentBehavior = UIAttachmentBehavior.slidingAttachment(
            with: enemyPaddleView,
            attachmentAnchor: .zero,
            axisOfTranslation: CGVector(dx: 1.0, dy: 0.0)
        )
        dynamicAnimator.addBehavior(attachmentBehavior)
    }
}

// NOTE: Это расширение определяет функции обработки столкновений в динамике элементов
extension PongViewController: UICollisionBehaviorDelegate {
    
    // MARK: - UICollisionBehaviorDelegate
    
    /// Эта функция обрабатывает столкновения объектов
    func collisionBehavior(
        _ behavior: UICollisionBehavior,
        beganContactFor item1: UIDynamicItem,
        with item2: UIDynamicItem,
        at p: CGPoint
    ) {
        
        guard
            let view1 = item1 as? UIView,
            let view2 = item2 as? UIView
        else { return }
        
        if view1.tag == Constants.ballTag || view2.tag == Constants.ballTag {
            if shouldBallBeAccelerated {
                tutorialState = 3
            }
            // если идет туториал, то мы сбрасываем мяч каждое столкновение
            // куда полетит мяч после ресета определяет состояние туториала (tutorialState)
            // соответствующий switch есть в необходимых для сброса функциях 
            // оно обновляется в GestureHandling
            if needTutorial {
                if view1.tag == Constants.userPaddleTag || view2.tag == Constants.userPaddleTag {
                    // использование дробной переменной tutorialStateTransitional позволяет переходить на следующее состояние только при соблюдении двух условий:
                    //удар отражен и ракетка достигла края
                    tutorialState = Int(tutorialStateTransitional + 0.1)
                }
                else {
                    tutorialState = Int(tutorialStateTransitional)
                }
                if tutorialState < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.resetBallWithAnimation()
                    }
                }
                else {
                    needTutorial = false
                }
            }
            else {
                animateBallHit(at: p,
                               color: shouldBallBeAccelerated ? UIColor.white : UIColor.systemOrange)
                playHitSound(.mid)
                lightImpactFeedbackGenerator.impactOccurred()
            }
        }
        if let ballDynamicBehavior = self.ballDynamicBehavior {
            ballDynamicBehavior.addLinearVelocity(
                ballDynamicBehavior.linearVelocity(for: self.ballView).multiplied(by: shouldBallBeAccelerated ?  Constants.ballAccelerationFactorForced : Constants.ballAccelerationFactor),
                for: self.ballView
            )
            // анимация ускоренного удара
            if shouldBallBeAccelerated {
                ballPushBehavior?.pushDirection = makeRandomVelocityVector(straight: true)
                for i in 0...3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 * Double(i)) {
                        self.animateBallHit(at: CGPoint(x: self.ballView.frame.maxX,
                                                        y: self.ballView.frame.maxY),
                                            color: UIColor.systemOrange)
                    }
                }
                shouldBallBeAccelerated = false
            }
        }
    }
    
    func collisionBehavior(
        _ behavior: UICollisionBehavior,
        beganContactFor item: UIDynamicItem,
        withBoundaryIdentifier identifier: NSCopying?,
        at p: CGPoint
    ) {
                
        // NOTE: Пытаемся опеределить по тэгу, является ли объект столкновения мячом
        guard
            identifier == nil,
            let itemView = item as? UIView,
            itemView.tag == Constants.ballTag
        else { return }
        
        animateBallHit(at: p,
                       color: UIColor.white)
        
        var shouldResetBall: Bool = false
        if abs(p.y) <= Constants.contactThreshold {
            // NOTE: Если место столкновения близко к верхней границе,
            // значит мяч ударился о верхнюю грань экрана
            //
            // Увеличиваем счет игрока
            userScore += 1
            shouldResetBall = true
        } else if abs(p.y - view.bounds.height) <= Constants.contactThreshold {
            // NOTE: Если место столкновения близко к нижней границе,
            // значит мяч ударился о нижнюю грань экрана
            shouldResetBall = true
            enemyScore += 1
        }
        
        if shouldResetBall {
            resetBallWithAnimation()
            playHitSound(.high)
            rigidImpactFeedbackGenerator.impactOccurred()
        } else {
            playHitSound(.low)
            softImpactFeedbackGenerator.impactOccurred()
        }
    }
    
    // MARK: - Utils
    /// Эта вспомогательная функция возвращает название элемента, определяя его по "тэгу"
    private func getNameFromViewTag(_ view: UIView) -> String {
        switch view.tag {
        case Constants.ballTag:
            return "Ball"
            
        case Constants.userPaddleTag:
            return "User Paddle"
            
        case Constants.enemyPaddleTag:
            return "Enemy Paddle"
            
        default:
            return "?"
        }
    }
}

// NOTE: Это расширение определяет функции для сброса мяча
extension PongViewController {
    
    // MARK: - Reset Ball
    
    /// Эта функция останавливает движение мяча и сбрасывает мяч его положение на середину экрана
    private func resetBallWithAnimation() {
        // NOTE: отсанавливаем движение мяча
        stopBallMovement()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // NOTE: через 1 секунду сбрасываем положение мяча и анимируем его появление
            self?.resetBallViewPositionAndAnimateBallAppear()
        }
    }
    
    /// Эта функция останавливает движение мяча
    private func stopBallMovement() {
        if let ballPushBehavior = self.ballPushBehavior {
            self.ballPushBehavior = nil
            ballPushBehavior.active = false
            dynamicAnimator?.removeBehavior(ballPushBehavior)
        }
        
        if let ballDynamicBehavior = self.ballDynamicBehavior {
            ballDynamicBehavior.addLinearVelocity(
                ballDynamicBehavior.linearVelocity(for: self.ballView).inverted(),
                for: self.ballView
            )
        }
        
        dynamicAnimator?.updateItem(usingCurrentState: self.ballView)
    }
    
    /// Эта функция сбрасывает положение мяча и анимирует его появление
    private func resetBallViewPositionAndAnimateBallAppear() {
        // NOTE: сбрасываем положение шарика
        resetBallViewPosition()
        dynamicAnimator?.updateItem(usingCurrentState: self.ballView)
        
        // NOTE: устанавливаем прозрачность и размер мяча
        ballView.alpha = 0.0
        ballView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                // устанавливаем прозрачность и размер мяча возвращая их к нормальному состоянию
                self.ballView.alpha = 1.0
                self.ballView.transform = .identity
            },
            completion: { [weak self] _ in
                /// по окончанию анимации включаем обработку следующего нажатия для запуска мяча
                self?.hasLaunchedBall = false
            }
        )
    }
    
    /// Эта функция сбрасывает положение мяча на центр экрана
    private func resetBallViewPosition() {
        // NOTE: сбрасываем любые трансформации мяча
        ballView.transform = .identity
        
        // NOTE: Сбрасываем положение мяча
        let ballSize: CGSize = ballView.frame.size
        ballView.frame = CGRect(
            origin: CGPoint(
                x: (view.bounds.width - ballSize.width) / 2,
                y: (view.bounds.height - ballSize.height) / 2
            ),
            size: ballSize
        )
    }
}
