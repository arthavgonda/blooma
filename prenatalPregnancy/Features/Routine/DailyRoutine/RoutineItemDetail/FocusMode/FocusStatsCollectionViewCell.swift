//
//  FocusStatsCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 08/04/26.
//

import UIKit

class FocusStatsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var statsView: UIView!
    
    @IBOutlet weak var heartView: UIView!
    @IBOutlet weak var spo2View: UIView!
    @IBOutlet weak var caloriesView: UIView!
    @IBOutlet weak var stepsView: UIView!
    
    @IBOutlet weak var heartIcon: UIImageView!
    @IBOutlet weak var spo2Icon: UIImageView!
    @IBOutlet weak var caloriesIcon: UIImageView!
    @IBOutlet weak var stepsIcon: UIImageView!
    
    @IBOutlet weak var heartLabel: UILabel!
    @IBOutlet weak var spo2Label: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    
    @IBOutlet weak var heartTitleLabel: UILabel!
    @IBOutlet weak var spo2TitleLabel: UILabel!
    @IBOutlet weak var caloriesTitleLabel: UILabel!
    @IBOutlet weak var stepsTitleLabel: UILabel!
    
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var onSkip: (() -> Void)?
    var onStop: (() -> Void)?
    
    private let timeLeftButton = UIButton(type: .system)
    private var didInstallTimeLeftButton = false
    private var didFadeInVitals = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    
    func configure(routineItem: RoutineItem, heartRate: Int, calories: Int, spo2: Int, steps: Int, theme: AppTheme) {
        setupUI(theme: theme)
        updateStats(heartRate: heartRate, calories: calories, spo2: spo2, steps: steps, routineType: routineItem.routineType)
    }
    
    func updateStats(heartRate: Int, calories: Int, spo2: Int, steps: Int, routineType: RoutineType) {
        animate(heartLabel, to: heartRate > 0 ? "\(heartRate) bpm" : "-- bpm")
        animate(caloriesLabel, to: "\(max(0, calories)) kcal")
        
        let movementTitle: String
        let movementUnit: String
        let movementIcon: String
        
        switch routineType {
        case .walking:
            movementTitle = "Steps"
            movementUnit = "steps"
            movementIcon = "figure.walk"
        case .exercise, .yoga:
            movementTitle = "Reps"
            movementUnit = "reps"
            movementIcon = "repeat"
        }
        
        animate(stepsLabel, to: "\(max(0, steps)) \(movementUnit)")
        
        [heartView, spo2View, caloriesView, stepsView].forEach {
            $0?.isHidden = false
            $0?.superview?.isHidden = false
        }
        
        spo2View.isHidden = true
        
        stepsTitleLabel.text = movementTitle
        stepsIcon.image = UIImage(systemName: movementIcon)
        stepsIcon.tintColor = .systemGreen
    }

    func updateTimeLeft(_ text: String) {
        timeLeftButton.setTitle(text, for: .normal)
    }
    
    private func setupUI(theme: AppTheme) {
        statsView.backgroundColor = .clear
        
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.cornerRadius = 24
        containerView.layer.cornerCurve = .continuous
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = theme.glassBorderStrong.withAlphaComponent(0.55).cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.12
        containerView.layer.shadowRadius = 18
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        containerView.clipsToBounds = false
        installBlur(in: containerView, cornerRadius: 24)
        
        [heartView, spo2View, caloriesView, stepsView].forEach {
            $0?.backgroundColor = .clear
        }
        
        setupIcons()
        setupLabels(theme: theme)
        setupSkipButton(theme: theme)
        setupStopButton(theme: theme)
        setupTimeLeftButton(theme: theme)
        fadeInVitalsIfNeeded()
    }
    
    private func setupIcons() {
        heartIcon.image = UIImage(systemName: "heart.fill")
        heartIcon.tintColor = .systemPink
        
        spo2Icon.image = UIImage(systemName: "drop.fill")
        spo2Icon.tintColor = .systemBlue
        
        caloriesIcon.image = UIImage(systemName: "flame.fill")
        caloriesIcon.tintColor = .systemOrange
        
        stepsIcon.image = UIImage(systemName: "figure.walk")
        stepsIcon.tintColor = .systemGreen
    }
    
    private func setupLabels(theme: AppTheme) {
        [heartLabel, spo2Label, caloriesLabel, stepsLabel].forEach {
            $0?.textColor = theme.primaryText
            $0?.font = .systemFont(ofSize: 17, weight: .semibold)
            $0?.backgroundColor = .clear
            $0?.textAlignment = .center
            $0?.adjustsFontSizeToFitWidth = true
            $0?.minimumScaleFactor = 0.75
        }
        
        heartTitleLabel.text = "Heart"
        spo2TitleLabel.text = "SpO2"
        caloriesTitleLabel.text = "Calories"
        stepsTitleLabel.text = "Steps"
        
        [heartTitleLabel, spo2TitleLabel, caloriesTitleLabel, stepsTitleLabel].forEach {
            $0?.textColor = theme.secondaryText
            $0?.font = .systemFont(ofSize: 12, weight: .regular)
            $0?.backgroundColor = .clear
            $0?.textAlignment = .center
        }
    }
    
    private func setupSkipButton(theme: AppTheme) {
        
        skipButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        
        skipButton.layer.cornerRadius = stopButton.layer.cornerRadius
        skipButton.layer.cornerCurve = .continuous
        
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        
        skipButton.layer.shadowColor = UIColor.black.cgColor
        skipButton.layer.shadowOpacity = 0.08
        skipButton.layer.shadowRadius = 10
        skipButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        
        skipButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(theme.primaryText, for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    }
    
    private func setupStopButton(theme: AppTheme) {
        
        stopButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
        
        stopButton.layer.cornerRadius = 24
        stopButton.layer.cornerCurve = .continuous
        stopButton.layer.borderWidth = 1
        stopButton.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.4).cgColor
        
        stopButton.layer.shadowColor = UIColor.systemRed.cgColor
        stopButton.layer.shadowOpacity = 0.25
        stopButton.layer.shadowRadius = 12
        stopButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        
        stopButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        
        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(.systemRed, for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    }

    private func setupTimeLeftButton(theme: AppTheme) {
        guard !didInstallTimeLeftButton else { return }
        didInstallTimeLeftButton = true

        timeLeftButton.translatesAutoresizingMaskIntoConstraints = false
        timeLeftButton.isUserInteractionEnabled = false
        timeLeftButton.backgroundColor = UIColor.white.withAlphaComponent(0.48)
        timeLeftButton.layer.cornerRadius = 21
        timeLeftButton.layer.cornerCurve = .continuous
        timeLeftButton.layer.borderWidth = 1
        timeLeftButton.layer.borderColor = UIColor.white.withAlphaComponent(0.58).cgColor
        timeLeftButton.layer.shadowColor = UIColor.black.cgColor
        timeLeftButton.layer.shadowOpacity = 0.10
        timeLeftButton.layer.shadowRadius = 12
        timeLeftButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        timeLeftButton.setTitleColor(theme.accentSecondary, for: .normal)
        timeLeftButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

        statsView.addSubview(timeLeftButton)
        NSLayoutConstraint.activate([
            timeLeftButton.topAnchor.constraint(equalTo: statsView.safeAreaLayoutGuide.topAnchor, constant: 10),
            timeLeftButton.centerXAnchor.constraint(equalTo: statsView.centerXAnchor),
            timeLeftButton.widthAnchor.constraint(equalTo: statsView.widthAnchor, multiplier: 0.62),
            timeLeftButton.heightAnchor.constraint(equalToConstant: 42)
        ])

        startFloatingTimeAnimation()
    }
    
    private func startFloatingTimeAnimation() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = -2
        animation.toValue = 2
        animation.duration = 1.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        timeLeftButton.layer.add(animation, forKey: "timeFloat")
    }
    
    private func installBlur(in view: UIView, cornerRadius: CGFloat) {
        let blurTag = 9001
        guard view.viewWithTag(blurTag) == nil else { return }
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blurView.tag = blurTag
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false
        blurView.layer.cornerRadius = cornerRadius
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        
        view.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func animate(_ label: UILabel, to text: String) {
        guard label.text != text else { return }
        
        UIView.transition(with: label, duration: 0.18, options: .transitionCrossDissolve) {
            label.text = text
        }
    }
    
    private func fadeInVitalsIfNeeded() {
        guard !didFadeInVitals else { return }
        didFadeInVitals = true
        
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0.03, options: [.curveEaseOut]) {
            self.containerView.alpha = 1
        }
    }
    
    @IBAction func skipTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.18) {
                sender.transform = .identity
            }
        }
        
        onSkip?()
    }
    
    @IBAction func stopTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }) { _ in
            UIView.animate(withDuration: 0.18) {
                sender.transform = .identity
            }
        }
        
        onStop?()
    }
}
