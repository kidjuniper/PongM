//
//  PongViewController+GestureHandling.swift
//  Pong
//
//  Created by Timofey on 17.05.2022.
//

import UIKit

// NOTE: В этом расширении мы настраиваем логику обработки жестов
extension PongViewController {
    
    // MARK: - Pan Gesture Handling
    
    /// Эта функция настраивает обработку жеста движения пальцем по экрану
    func enabledPanGestureHandling() {
        // NOTE: Создаем объект обработчика жеста
        let panGestureRecognizer = UIPanGestureRecognizer()
        
        // NOTE: Добавляем обработчик жеста к представлению экрана
        view.addGestureRecognizer(panGestureRecognizer)
        
        // NOTE: Указываем обработчику какую функцию вызывать при обработке жеста
        panGestureRecognizer.addTarget(self,
                                       action: #selector(self.handlePanGesture(_:)))
        
        // NOTE: Сохраняем объект обработчика жеста в переменную класса
        self.panGestureRecognizer = panGestureRecognizer
    }
    
    /// Эта функция обработки жеста.
    /// Она вызывается каждый раз, когда пользователь двигает пальцем по экрану или касается его
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        // NOTE: Смотрим на состояние обработчика жеста
        switch recognizer.state {
        case .began:
            // NOTE: Жест начал распознаваться, запоминаем текущую позицию платформы
            // Это состояние, когда пользователь только коснулся экрана
            lastUserPaddleOriginLocation = userPaddleView.frame.origin
            lastChangedLocation = userPaddleView.frame.origin.y
            
            shouldBallBeAccelerated = false
            
        case .changed:
            let velocity = recognizer.velocity(in: view)
            
            // NOTE: Произошло изменение касания,
            // вычисляем смещение пальца и обновляем положение плафтормы
            let translation: CGPoint = recognizer.translation(in: view)
            
            // проверяем ускорение; если больше величины N, то ускорение будет больше
            
            shouldBallBeAccelerated = velocity.y < -750 ? true : false
            
            // чуть ускоряем движения по X для удобства
            let translatedOriginX: CGFloat = lastUserPaddleOriginLocation.x + (translation.x * 1.3)
            
            // делаем плавнее ход фишки по Y, чтобы не пропускать отскоки
            let translatedOriginY: CGFloat = lastUserPaddleOriginLocation.y + (translation.y * 0.5)
            
            let platformWidthRatio = userPaddleView.frame.width / view.bounds.width
            let platformHeightRatio = userPaddleView.frame.height / view.bounds.height
            var minX: CGFloat = 0
            if needTutorial && tutorialState == 0 {
                minX = (view.bounds.width / 2) * (1 - platformWidthRatio)
            }
            
            let maxX: CGFloat = view.bounds.width * (1 - platformWidthRatio)
            let minY: CGFloat = view.bounds.height - userPaddleView.bounds.height - userPaddleView.frame.height
            let maxY: CGFloat = view.bounds.height - view.bounds.height * (0.2 - platformHeightRatio)
            
            
            userPaddleView.frame.origin.x = min(max(translatedOriginX,
                                                    minX),
                                                maxX)
            
            userPaddleView.frame.origin.y = max(min(translatedOriginY,
                                                    minY),
                                                maxY)
            
            lastChangedLocation = translation.y
            if translatedOriginY < maxY {
                accessLine.layer.opacity = 1
                rigidImpactFeedbackGenerator.impactOccurred()
            }
            else {
                accessLine.layer.opacity = 0
            }
            
            dynamicAnimator?.updateItem(usingCurrentState: userPaddleView)
            
            // MARK: tutorial handling
            if needTutorial {
                if tutorialState != 2 {
                    var point = recognizer.location(in: horizontalArrowImageView)
                    point.y = 89
                    point.x = (userPaddleView.frame.maxX + userPaddleView.frame.minX) / 2
                    
                    if velocity.x < 0 {
                        point.x = userPaddleView.frame.minX
                    }
                    path.move(to: point)
                    path.addArc(withCenter: point,
                                radius: 40,
                                startAngle: 0,
                                endAngle: .pi * 2,
                                clockwise: true)
                    
                    shapeLayer.path = self.path.cgPath
                    shapeLayer.fillRule = .nonZero
                    
                    // вычисляем необходимый tutorial state
                    if path.bounds.standardized.minX < 20 && path.bounds.standardized.maxX > horizontalArrowImageView.bounds.width - 20 {
                        tutorialStateTransitional = 1.9
                    }
                    else if path.bounds.standardized.maxX > horizontalArrowImageView.bounds.width - 20 {
                        tutorialStateTransitional = 0.9
                    }
                }
                else {
                    var point = recognizer.location(in: verticalArrowImageView)
                    point.x = 85
                    pathV.move(to: point)
                    pathV.addArc(withCenter: point,
                                radius: 40,
                                startAngle: 0,
                                endAngle: .pi * 2,
                                clockwise: true)
                    
                    shapeLayerVertical.path = self.pathV.cgPath
                    shapeLayerVertical.fillRule = .nonZero
                    
                    // вычисляем необходимый tutorial state
                }
            }
            
        default:
            // NOTE: При любом другом состоянии ничего не делаем
            break
        }
    }
}
