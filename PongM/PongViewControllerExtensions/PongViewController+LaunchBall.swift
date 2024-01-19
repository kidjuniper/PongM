//
//  PongViewController+LaunchBall.swift
//  Pong
//
//  Created by Timofey on 17.05.2022.
//

import Foundation
import UIKit

// NOTE: Это расширение определяет функцию используемую для запуска мяча
extension PongViewController {

    /// Функция запуска мяча. Генерирует рандомный вектор скорости мяча и запускает мяч по этому вектору
    func launchBall(straight: Bool) {
        let ballPusher = UIPushBehavior(items: [ballView], 
                                        mode: .instantaneous)
        self.ballPushBehavior = ballPusher

        ballPusher.pushDirection = makeRandomVelocityVector(straight: straight)
        ballPusher.active = true

        self.dynamicAnimator?.addBehavior(ballPusher)
    }

    /// Функция генерации вектора скорости запуска мяча с почти рандомным направлением
    func makeRandomVelocityVector(straight: Bool) -> CGVector {
        // NOTE: Генерируем рандомное число от 0 до 1
        let randomSeed = Double(arc4random_uniform(500) + 500) / 1000

        // NOTE: Создаем рандомный угол примерно между Pi/6 (30 градусов) и Pi/3 (60 градусов)
        var angle = Double.pi * (0.16 + 0.16 * randomSeed)
        
        if straight {
            switch tutorialState {
            case 0:
                angle = Double.pi * (0.35)
            case 1:
                angle = Double.pi * (0.65)
            case 2:
                angle = Double.pi * (0.65)
            default: break
            }
        }

        // NOTE: Берем в качестве амплитуды (силы) запуска мяча 1.5 пикселя экрана
        let amplitude = 1.5 / UIScreen.main.scale

        // NOTE: разложение вектора скорости на оси X и Y
        let x = amplitude * cos(angle)
        let y = amplitude * sin(angle)

        // NOTE: используя сгенерированный угол, возвращаем его в одном из 4 вариаций
        
        if straight {
            return CGVector(dx: x, dy: y)
        }
            
            
        switch arc4random() % 4 {
        case 0:
            // направо, вниз
            return CGVector(dx: x, dy: y)

        case 1:
            // направо, вверх
            return CGVector(dx: x, dy: -y)

        case 2:
            // налево, вниз
            return CGVector(dx: -x, dy: y)

        default:
            // налево, вверх
            return CGVector(dx: -x, dy: -y)
        }
    }
}
