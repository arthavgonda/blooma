//
//  AppTheme.swift
//  prenatalPregnancy
//
//  Created by GEU on 20/03/26.
//

import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

final class AnimatedBackgroundView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let noiseLayer = CALayer()
    private var currentTheme: AppTheme
    private var hasStartedAnimating = false

    init(theme: AppTheme) {
        currentTheme = theme
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        configureLayers()
        update(theme: theme)
    }

    required init?(coder: NSCoder) { return nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        noiseLayer.frame = bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !hasStartedAnimating else { return }
        hasStartedAnimating = true
        startAnimating()
    }

    func update(theme: AppTheme) {
        currentTheme = theme

        gradientLayer.colors = [
            theme.backgroundGradientStart.cgColor,
            UIColor(hex: "#EDDADF").cgColor,
            theme.backgroundGradientEnd.cgColor
        ]

        gradientLayer.locations = [0.0, 0.6, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 1.0)

        noiseLayer.contents = makeNoiseImage()?.cgImage
    }

    private func configureLayers() {
        layer.addSublayer(gradientLayer)

        noiseLayer.opacity = 0.02
        noiseLayer.contentsGravity = .resizeAspectFill
        layer.addSublayer(noiseLayer)
    }

    private func startAnimating() {
        let start = CABasicAnimation(keyPath: "startPoint")
        start.fromValue = CGPoint(x: 0.1, y: 0.0)
        start.toValue = CGPoint(x: 0.8, y: 0.2)

        let end = CABasicAnimation(keyPath: "endPoint")
        end.fromValue = CGPoint(x: 0.9, y: 1.0)
        end.toValue = CGPoint(x: 0.2, y: 0.9)

        let group = CAAnimationGroup()
        group.animations = [start, end]
        group.duration = 18
        group.autoreverses = true
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        gradientLayer.add(group, forKey: "gradientMove")

    }

    private func makeNoiseImage() -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            for y in stride(from: 0, to: Int(size.height), by: 2) {
                for x in stride(from: 0, to: Int(size.width), by: 2) {
                    let alpha = CGFloat.random(in: 0...0.02)
                    cg.setFillColor(UIColor.black.withAlphaComponent(alpha).cgColor)
                    cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
    }
}

extension UIWindow {

    func installGlobalParticleOverlay(theme: AppTheme) {
        // Background objects are intentionally disabled.
    }
}

extension UIViewController {

    func applyAnimatedBackground(theme: AppTheme) {
        let bg: AnimatedBackgroundView

        if let existing = view.subviews.first(where: { $0 is AnimatedBackgroundView }) as? AnimatedBackgroundView {
            bg = existing
            bg.update(theme: theme)
        } else {
            bg = AnimatedBackgroundView(theme: theme)
            bg.frame = view.bounds
            bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(bg, at: 0)
        }

        view.backgroundColor = .clear
        view.sendSubviewToBack(bg)
    }

    func circularIconBarButton(systemName: String, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = UIColor(hex: "#C96A86")
        button.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        button.layer.cornerRadius = 17
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.65).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.12
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.addTarget(self, action: #selector(softIconButtonTouchDown(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(softIconButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 34)
        ])

        return UIBarButtonItem(customView: button)
    }

    @objc private func softIconButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func softIconButtonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.6, options: [.allowUserInteraction]) {
            sender.transform = .identity
        }
    }

    func configureSoftNavigationBar(theme: AppTheme) {
        guard let nav = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.backgroundGradientStart
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: theme.primaryText
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: theme.primaryText
        ]

        nav.standardAppearance = appearance
        nav.scrollEdgeAppearance = appearance
        nav.compactAppearance = appearance
        nav.isTranslucent = false
        nav.tintColor = theme.accentPrimary
    }
}

extension DataController {

    var theme: AppTheme {

        let coral = UIColor(hex: "#F48FB1")
        let rose = UIColor(hex: "#C96A86")

        let bgStart = UIColor(hex: "#F3E8EE")
        let bgEnd = UIColor(hex: "#E6C7D0")

        let glassUltraThin = UIColor.white.withAlphaComponent(0.15)
        let glassThin = UIColor.white.withAlphaComponent(0.25)
        let glassMedium = UIColor.white.withAlphaComponent(0.40)
        let glassStrong = UIColor.white.withAlphaComponent(0.65)

        let glassBorderLight = UIColor.white.withAlphaComponent(0.4)
        let glassBorderStrong = UIColor.white.withAlphaComponent(0.8)

        let shadowSoft = UIColor.black.withAlphaComponent(0.08)
        let shadowMedium = UIColor.black.withAlphaComponent(0.15)

        let primaryText = UIColor(hex: "#1A1A1A")
        let secondaryText = UIColor(hex: "#555555")
        let tertiaryText = UIColor(hex: "#777777")

        let buttonGlass = UIColor.white.withAlphaComponent(0.25)
        let buttonBorder = UIColor.white.withAlphaComponent(0.5)

        let inputGlass = UIColor.white.withAlphaComponent(0.30)
        let inputBorder = coral.withAlphaComponent(0.25)

        let success = UIColor(hex: "#A8E6CF").withAlphaComponent(0.8)
        let warning = UIColor(hex: "#FFD8A8").withAlphaComponent(0.8)
        let error = UIColor(hex: "#FFB3B3").withAlphaComponent(0.8)

        let divider = UIColor.white.withAlphaComponent(0.3)
        let shimmer = UIColor.white.withAlphaComponent(0.28)

        return AppTheme(
            backgroundGradientStart: bgStart,
            backgroundGradientEnd: bgEnd,
            glassUltraThin: glassUltraThin,
            glassThin: glassThin,
            glassMedium: glassMedium,
            glassStrong: glassStrong,
            glassBorderLight: glassBorderLight,
            glassBorderStrong: glassBorderStrong,
            shadowSoft: shadowSoft,
            shadowMedium: shadowMedium,
            primaryText: primaryText,
            secondaryText: secondaryText,
            tertiaryText: tertiaryText,
            accentPrimary: coral,
            accentSecondary: rose,
            buttonGlassBackground: buttonGlass,
            buttonGlassBorder: buttonBorder,
            buttonText: primaryText,
            inputGlassBackground: inputGlass,
            inputGlassBorder: inputBorder,
            success: success,
            warning: warning,
            error: error,
            divider: divider,
            shimmer: shimmer
        )
    }
}

extension RoutineType {
    var accentColor: UIColor {
        switch self {
        case .walking: return .systemGreen
        case .exercise: return .systemPurple
        case .yoga: return .systemPink
        }
    }
}
