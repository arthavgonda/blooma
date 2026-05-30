//
//  RecommendedFlowCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 27/03/26.
//

import UIKit

class RecommendedFlowCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var walkingView: UIView!
    @IBOutlet weak var exerciseView: UIView!
    @IBOutlet weak var yogaView: UIView!
    
    @IBOutlet weak var walkingIcon: UIImageView!
    @IBOutlet weak var exerciseIcon: UIImageView!
    @IBOutlet weak var yogaIcon: UIImageView!
    
    @IBOutlet weak var arrow1: UIImageView!
    @IBOutlet weak var arrow2: UIImageView!
    
    private var activeIndex: Int = 0
    private var timer: Timer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .clear
        setupUI()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        timer?.invalidate()
        timer = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layoutIfNeeded()
        updateCornerRadius()
        updateUI()
    }
    
    private func updateCornerRadius() {
        [walkingView, exerciseView, yogaView].forEach {
            $0?.layer.cornerRadius = ($0?.bounds.height ?? 0) / 2
            $0?.clipsToBounds = true
        }
    }
    
    private func setupUI() {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        
        arrow1.image = UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: config)
        arrow2.image = UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: config)
        
        animateArrow(arrow1)
        animateArrow(arrow2)
    }
    
    func configure(theme: AppTheme) {
        
        let walking = RoutineType.walking
        let exercise = RoutineType.exercise
        let yoga = RoutineType.yoga
        
        walkingIcon.image = UIImage(systemName: walking.iconName)
        exerciseIcon.image = UIImage(systemName: exercise.iconName)
        yogaIcon.image = UIImage(systemName: yoga.iconName)
        
        walkingIcon.tintColor = walking.accentColor
        exerciseIcon.tintColor = exercise.accentColor
        yogaIcon.tintColor = yoga.accentColor
        
        [walkingView, exerciseView, yogaView].forEach { view in
            view?.backgroundColor = theme.glassMedium
            view?.layer.borderWidth = 1
            view?.layer.borderColor = theme.glassBorderLight.cgColor
            if let view = view {
                applyGlassEffect(to: view)
            }
        }
        
        arrow1.tintColor = theme.tertiaryText
        arrow2.tintColor = theme.tertiaryText
        
        activeIndex = 0
        updateUI()
        
        startAutoFlow()
    }
    
    private func updateUI() {
        
        let views = [walkingView, exerciseView, yogaView]
        let icons = [walkingIcon, exerciseIcon, yogaIcon]
        
        for (index, view) in views.enumerated() {
            
            guard let view = view else { continue }
            
            let isActive = index == activeIndex
            
            UIView.animate(withDuration: 0.4) {
                view.transform = isActive ? CGAffineTransform(scaleX: 1.2, y: 1.2) : CGAffineTransform(scaleX: 0.9, y: 0.9)
                view.alpha = isActive ? 1.0 : 0.5
            }
            
            view.layer.sublayers?.removeAll(where: { $0.name == "gradientBorder" })
            view.layer.removeAnimation(forKey: "floating")
            
            if isActive {
                if let color = icons[index]?.tintColor {
                    addGradientBorder(to: view, color: color)
                }
                addFloatingAnimation(to: view)
            }
        }
        
        updateArrows()
    }
    
    private func updateArrows() {
        
        if activeIndex == 0 {
            arrow1.tintColor = .systemGray3
            arrow2.tintColor = .systemGray3
        } else if activeIndex == 1 {
            arrow1.tintColor = .label
            arrow2.tintColor = .systemGray3
        } else {
            arrow1.tintColor = .label
            arrow2.tintColor = .label
        }
    }
    
    private func startAutoFlow() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.activeIndex = (self.activeIndex + 1) % 3
            self.updateUI()
        }
    }
    
    private func addFloatingAnimation(to view: UIView) {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = -4
        animation.toValue = 4
        animation.duration = 1.2
        animation.autoreverses = true
        animation.repeatCount = .infinity
        view.layer.add(animation, forKey: "floating")
    }
    
    private func animateArrow(_ arrow: UIImageView) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.3
        animation.toValue = 1
        animation.duration = 0.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        arrow.layer.add(animation, forKey: "blink")
    }
    
    private func applyGlassEffect(to view: UIView) {
        
        let existingBlur = view.subviews.first { $0 is UIVisualEffectView }
        if existingBlur != nil { return }
        
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blur)
        
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = view.bounds.height / 2
        blurView.clipsToBounds = true
        
        view.insertSubview(blurView, at: 0)
    }
    
    private func addGradientBorder(to view: UIView, color: UIColor) {
        
        view.layer.sublayers?.removeAll(where: { $0.name == "gradientBorder" })
        
        let gradient = CAGradientLayer()
        gradient.name = "gradientBorder"
        gradient.frame = view.bounds
        gradient.colors = [color.withAlphaComponent(0.6).cgColor, color.withAlphaComponent(0.2).cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 1.5
        shape.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.bounds.height / 2).cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.black.cgColor
        
        gradient.mask = shape
        
        view.layer.addSublayer(gradient)
    }
    
    func updateFlow(activeIndex: Int) {
        self.activeIndex = activeIndex
        updateUI()
    }
    
}
