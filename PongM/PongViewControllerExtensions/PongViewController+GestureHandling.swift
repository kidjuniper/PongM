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
        panGestureRecognizer.addTarget(self, action: #selector(self.handlePanGesture(_:)))

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
            
            shouldBallBeAccelerated = false

        case .changed:
            // NOTE: Произошло изменение касания,
            // вычисляем смещение пальца и обновляем положение плафтормы
            let translation: CGPoint = recognizer.translation(in: view)
            
            // проверяем ускорение; если больше величины N, то ускорение будет больше
            let velocity = recognizer.velocity(in: view)
            shouldBallBeAccelerated = velocity.y < -750 ? true : false
            
            // делаем разбиение перемещения, чтобы при резком движении отскок все равно ловился
            for i in 0...30 {
                let translatedOriginX: CGFloat = lastUserPaddleOriginLocation.x + (translation.x / 30.0) * CGFloat(i)
                let translatedOriginY = lastUserPaddleOriginLocation.y + (translation.y / 30.0) * CGFloat(i)

                let platformWidthRatio = userPaddleView.frame.width / view.bounds.width
                let platformHeightRatio = userPaddleView.frame.height / view.bounds.height
                let minX: CGFloat = 0
                let maxX: CGFloat = view.bounds.width * (1 - platformWidthRatio)
                let minY: CGFloat = view.bounds.height - userPaddleView.bounds.height - userPaddleView.frame.height
                let maxY: CGFloat = view.bounds.height - view.bounds.height * (0.2 - platformHeightRatio)
                
                userPaddleView.frame.origin.x = min(max(translatedOriginX, minX), maxX)
                userPaddleView.frame.origin.y = max(min(translatedOriginY, minY), maxY)
                
                if translatedOriginY < maxY {
                    accessLine.layer.opacity = 1
                }
                else {
                    accessLine.layer.opacity = 0
                }
                
                dynamicAnimator?.updateItem(usingCurrentState: userPaddleView)
            }
            
        default:
            // NOTE: При любом другом состоянии ничего не делаем
            break
        }
    }
}
