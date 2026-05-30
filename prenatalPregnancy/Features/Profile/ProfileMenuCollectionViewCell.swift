//
//  ProfileMenuCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 24/03/26.
//

import UIKit

class ProfileMenuCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    private let borderLayer = CAShapeLayer()
    
    private var isFirst = false
    private var isLast = false
    private var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        borderLayer.path = nil
    }
    
    private func setupUI() {
        
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        containerView.layer.borderWidth = 1
        
        containerView.layer.masksToBounds = true
        
        containerView.layer.shadowOpacity = 0
        
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1
        borderLayer.contentsScale = traitCollection.displayScale
        
        if borderLayer.superlayer == nil {
            containerView.layer.addSublayer(borderLayer)
        }

        titleLabel.textColor = theme.primaryText
        
        iconImageView.tintColor = theme.accentPrimary
        
        chevronImageView.tintColor = theme.secondaryText
        chevronImageView.image = UIImage(systemName: "chevron.right")
    }
    
    func configure(row: ProfileRow, isFirst: Bool, isLast: Bool, theme: AppTheme) {
        
        self.theme = theme
        self.isFirst = isFirst
        self.isLast = isLast
        
        setupUI()
        
        iconImageView.image = UIImage(systemName: row.icon)
        
        containerView.layer.cornerRadius = 0
        containerView.layer.maskedCorners = []
        
        let radius: CGFloat = 16
        
        if isFirst && isLast {
            containerView.layer.cornerRadius = radius
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            containerView.layer.cornerRadius = radius
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            containerView.layer.cornerRadius = radius
            containerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        titleLabel.text = row.title
        
        containerView.layoutIfNeeded()
        drawBorders()
    }
    
    private func drawBorders() {
        guard containerView.bounds.width > 0, theme != nil else { return }
        
        let w = containerView.bounds.width
        let h = containerView.bounds.height
        let r: CGFloat = (isFirst || isLast) ? 16 : 0
        
        let path = UIBezierPath()
        
        if isFirst && isLast {
            let rect = CGRect(x: 0, y: 0, width: w, height: h)
            path.append(UIBezierPath(roundedRect: rect, cornerRadius: r))
            
        } else if isFirst {
            
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: 0, y: r))
            
            path.addArc(withCenter: CGPoint(x: r, y: r), radius: r, startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
            
            path.addLine(to: CGPoint(x: w - r, y: 0))
            
            path.addArc(withCenter: CGPoint(x: w - r, y: r), radius: r, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
            
            path.addLine(to: CGPoint(x: w, y: h))
            
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w, y: h))
            
        } else if isLast {
            
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: h - r))
            
            path.addArc(withCenter: CGPoint(x: r, y: h - r), radius: r, startAngle: .pi, endAngle: .pi / 2, clockwise: false)
            
            path.addLine(to: CGPoint(x: w - r, y: h))
            
            path.addArc(withCenter: CGPoint(x: w - r, y: h - r), radius: r, startAngle: .pi / 2, endAngle: 0, clockwise: false)
            
            path.addLine(to: CGPoint(x: w, y: 0))
            
        } else {
            
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: h))
            
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: w, y: 0))
        }
        
        borderLayer.path = path.cgPath
    }
    
}
