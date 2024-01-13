import UIKit
import AVFoundation

class PongViewController: UIViewController {

    // MARK: - Subviews

    /// Это переменная отображения мяча
    @IBOutlet var ballView: UIView!

    /// Это переменная отображения платформы игрока
    @IBOutlet var userPaddleView: UIView!

    /// Это переменная отображения платформы соперника
    @IBOutlet var enemyPaddleView: UIView!

    /// Это переменная отображения разделяющей линии
    @IBOutlet var lineView: UIView!
    
    lazy var gateLine: UIView = {
        let view = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: 0,
                                        height: 0))
        return view
    }()
    lazy var accessLine: UIView = {
        let view = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: 0,
                                        height: 0))
        return view
    }()

    /// Это переменная отображения лэйбла со счетом игрока
    @IBOutlet var userScoreLabel: UILabel!

    // MARK: - Instance Properties

    /// Это переменная обработчика жеста движения пальцем по экрану
    var panGestureRecognizer: UIPanGestureRecognizer?

    /// Это переменная в которой мы будем запоминать последнее положение платформы пользователя,
    /// перед тем как пользователь начал двигать пальцем по экрану
    var lastUserPaddleOriginLocation: CGPoint = CGPoint()

    /// Это переменная таймера, который будет обновлять положение платформы соперника
    var enemyPaddleUpdateTimer: Timer?

    var shouldLaunchBallOnNextTap: Bool = false

    /// Это флаг `Bool`, который указывает "был ли запущен мяч"
    var hasLaunchedBall: Bool = false
    
    // это флаг, который проверяет, нужно ли ускорять мач при ударе с амплитудой
    var shouldBallBeAccelerated: Bool = false

    var enemyPaddleUpdatesCounter: UInt8 = 0

    // NOTE: Все переменные ниже вплоть до 74-ой строки необходимы для настроек физики
    // Мы не будем вдаваться в подробности того, что это такое и как устроено
    var dynamicAnimator: UIDynamicAnimator?
    var ballPushBehavior: UIPushBehavior?
    var ballDynamicBehavior: UIDynamicItemBehavior?
    var userPaddleDynamicBehavior: UIDynamicItemBehavior?
    var enemyPaddleDynamicBehavior: UIDynamicItemBehavior?
    var collisionBehavior: UICollisionBehavior?

    var audioPlayers: [AVAudioPlayer] = []
    var audioPlayersLock = NSRecursiveLock()
    var softImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    var lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var rigidImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)

    /// Эта переменная плеера предназначена для повторяющегося проигрывания фоновой музыки в игре
    var backgroundSoundAudioPlayer: AVAudioPlayer? = {
        guard
            let backgroundSoundURL = Bundle.main.url(forResource: "background",
                                                     withExtension: "wav"),
            let audioPlayer = try? AVAudioPlayer(contentsOf: backgroundSoundURL)
        else { return nil }

        audioPlayer.volume = 0.5
        audioPlayer.numberOfLoops = -1

        return audioPlayer
    }()

    /// Эта переменная хранит счет пользователя
    var userScore: Int = 0 {
        didSet {
            /// При каждом обновлении значения переменной - обновляем текст в лэйбле
            updateUserScoreLabel()
        }
    }

    // MARK: - Instance Methods

    /// Эта функция запускается 1 раз когда представление экрана загрузилось
    /// и вот-вот покажется в окне отображения
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [gateLine,
         accessLine].forEach { item in
            view.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }
        accessLine.backgroundColor = .red.withAlphaComponent(0.3)
        gateLine.backgroundColor = .red.withAlphaComponent(0.45)
        
        let platformHeightRatio = userPaddleView.frame.height / view.bounds.height
        let c = view.bounds.height * (0.2 - platformHeightRatio) + 2
        
        gateLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gateLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     gateLine.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                                       constant: -65),
                                     gateLine.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.95),
                                     gateLine.heightAnchor.constraint(equalToConstant: 2),
                                     
                                     accessLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     accessLine.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                                    constant: -c),
                                     accessLine.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.95),
                                     accessLine.heightAnchor.constraint(equalToConstant: 2)
                                    ])
    
        configurePongGame()
    }

    /// Эта функция вызывается, когда экран PongViewController повяился на экране телефона
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // NOTE: Включаем динамику взаимодействия
        self.enableDynamics()
    }

    /// Эта функция вызывается, когда экран первый раз отрисовал весь свой интерфейс
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // NOTE: Устанавливаем шару радиус скругления равный половине высоты
        ballView.layer.cornerRadius = ballView.bounds.size.height / 2
        ballView.backgroundColor = .systemGreen
        userPaddleView.backgroundColor = .systemGray4
        enemyPaddleView.backgroundColor = .systemGray4
    }

    /// Эта функция обрабатывает начало всех касаний экрана
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)

        // NOTE: Если нужно запустить мяч и мяч еще не был запущен - запускаем мяч
        if shouldLaunchBallOnNextTap, !hasLaunchedBall {
            hasLaunchedBall = true
            launchBall()
        }
    }

    // MARK: - Private Methods

    /// Эта функция выполняет выполняет всю конфигурацию (настройку) экрана
    ///
    /// - включает обработку жеста движения пальцем по экрану
    /// - включает динамику взаимодействия элементов
    /// - указывает что при следующем нажатии мяч должен запуститься
    ///
    private func configurePongGame() {
        // NOTE: Настраиваем лэйбл со счетом игрока
        updateUserScoreLabel()

        // NOTE: Включаем обработку жеста движения пальцем по экрану
        self.enabledPanGestureHandling()

        // NOTE: Включаем логику платформы противника "следовать за мечом"
        self.enableEnemyPaddleFollowBehavior()

        // NOTE: Указываем, что при следующем нажатии на экран нужно запустить мяч
        self.shouldLaunchBallOnNextTap = true

        // NOTE: Начинаем проигрывать фоновую музыку
        self.backgroundSoundAudioPlayer?.prepareToPlay()
        self.backgroundSoundAudioPlayer?.play()
    }

    private func updateUserScoreLabel() {
        userScoreLabel.text = "\(userScore)"
    }
}
