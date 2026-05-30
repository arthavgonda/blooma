//
//  MedicalConditionCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 09/02/26.
//

import UIKit

class MedicalConditionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var conditionButton: UIButton!
    
    var theme: AppTheme!
    private var blurView: UIVisualEffectView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        setupUI()
        // Initialization code
    }
    
    private func setupUI() {
        conditionButton.isUserInteractionEnabled = false
        
        conditionButton.layer.cornerRadius = 20
        conditionButton.layer.borderWidth = 0
        
        conditionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        conditionButton.titleLabel?.lineBreakMode = .byTruncatingTail
        
        conditionButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    }
    
    func configure(title: String, isSelected: Bool, style: Style = .normal, theme: AppTheme) {
        self.theme = theme
        conditionButton.setTitle(title, for: .normal)
        
        switch style {
        case .normal:
            applyNormalStyle(selected: isSelected)
        case .action:
            applyActionStyle()
        }
    }
    
    private func applyNormalStyle(selected: Bool) {
        
        let tint = theme.accentPrimary
        blurView?.removeFromSuperview()
        blurView = nil
        applyGlassEffect()
        
        if selected {
            conditionButton.backgroundColor = tint.withAlphaComponent(0.12)
            conditionButton.layer.borderWidth = 2
            conditionButton.layer.borderColor = tint.cgColor
            conditionButton.setTitleColor(theme.primaryText, for: .normal)
            
            conditionButton.layer.shadowOpacity = 0
            
        } else {
            conditionButton.backgroundColor = theme.glassMedium
            conditionButton.layer.borderWidth = 1
            conditionButton.layer.borderColor = theme.glassBorderStrong.withAlphaComponent(0.45).cgColor
            conditionButton.setTitleColor(theme.secondaryText, for: .normal)
            
            conditionButton.layer.shadowColor = UIColor.black.cgColor
            conditionButton.layer.shadowOpacity = 0.08
            conditionButton.layer.shadowRadius = 8
            conditionButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        }
    }
    
    private func applyActionStyle() {
        
        let tint = theme.accentPrimary
        blurView?.removeFromSuperview()
        blurView = nil
        
        conditionButton.backgroundColor = theme.glassMedium
        conditionButton.layer.borderWidth = 1
        conditionButton.layer.borderColor = theme.glassBorderStrong.withAlphaComponent(0.45).cgColor
        conditionButton.setTitleColor(tint, for: .normal)
        
        conditionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    private func applyGlassEffect() {
        
        blurView?.removeFromSuperview()
        
        let blur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blur)
        
        blurView.frame = conditionButton.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        blurView.layer.cornerRadius = conditionButton.layer.cornerRadius
        blurView.clipsToBounds = true
        
        blurView.isUserInteractionEnabled = false
        
        blurView.alpha = 0.6
        
        conditionButton.insertSubview(blurView, at: 0)
        
        self.blurView = blurView
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }
    
}
