//
//  RoutineItemDetailCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 04/02/26.
//

import UIKit

class RoutineItemDetailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    
    private let borderLayer = CAShapeLayer()
    private var isFirst = false
    private var isLast = false
    private var theme: AppTheme?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        contentLabel.numberOfLines = 5
        contentLabel.lineBreakMode = .byTruncatingTail
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentLabel.text = nil
        borderLayer.path = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawBorders()
    }
    
    func configureDescription(_ text: String, theme: AppTheme, isFirst: Bool = true, isLast: Bool = true) {
        applyTheme(theme)
        applySectionCorners(isFirst: isFirst, isLast: isLast)
        contentLabel.text = text
    }
    
    func configurePoint(_ text: String, theme: AppTheme, isFirst: Bool, isLast: Bool) {
        applyTheme(theme)
        applySectionCorners(isFirst: isFirst, isLast: isLast)
        contentLabel.text = text
    }
    
    private func applyTheme(_ theme: AppTheme) {
        self.theme = theme
        cardView.layer.borderColor = theme.glassBorderLight.cgColor
        cardView.layer.borderWidth = 1
        cardView.clipsToBounds = true
        cardView.backgroundColor = theme.glassMedium
        contentLabel.textColor = theme.primaryText
        contentLabel.font = .systemFont(ofSize: 13, weight: .medium)
        
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1
        borderLayer.contentsScale = traitCollection.displayScale
        
        if borderLayer.superlayer == nil {
            cardView.layer.addSublayer(borderLayer)
        }
    }
    
    private func applySectionCorners(isFirst: Bool, isLast: Bool) {
        self.isFirst = isFirst
        self.isLast = isLast
        
        cardView.layer.cornerRadius = 0
        cardView.layer.maskedCorners = []
        
        let radius: CGFloat = 22
        
        if isFirst && isLast {
            cardView.layer.cornerRadius = radius
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            cardView.layer.cornerRadius = radius
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            cardView.layer.cornerRadius = radius
            cardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        cardView.layoutIfNeeded()
        drawBorders()
    }
    
    private func drawBorders() {
        guard cardView.bounds.width > 0, theme != nil else { return }
        
        let width = cardView.bounds.width
        let height = cardView.bounds.height
        let radius: CGFloat = (isFirst || isLast) ? 22 : 0
        let path = UIBezierPath()
        
        if isFirst && isLast {
            path.append(UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: height), cornerRadius: radius))
        } else if isFirst {
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: width - radius, y: 0))
            path.addArc(withCenter: CGPoint(x: width - radius, y: radius), radius: radius, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
            path.addLine(to: CGPoint(x: width, y: height))
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: width, y: height))
        } else if isLast {
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: height - radius))
            path.addArc(withCenter: CGPoint(x: radius, y: height - radius), radius: radius, startAngle: .pi, endAngle: .pi / 2, clockwise: false)
            path.addLine(to: CGPoint(x: width - radius, y: height))
            path.addArc(withCenter: CGPoint(x: width - radius, y: height - radius), radius: radius, startAngle: .pi / 2, endAngle: 0, clockwise: false)
            path.addLine(to: CGPoint(x: width, y: 0))
        } else {
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        borderLayer.path = path.cgPath
    }
}
