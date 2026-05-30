//
//  PermissionCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 03/04/26.
//

import UIKit

class PermissionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.shadowPath = UIBezierPath(
            roundedRect: containerView.bounds,
            cornerRadius: 16
        ).cgPath
    }
    
    private func setupUI() {
        
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.cornerRadius = 16
        
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        containerView.layer.borderWidth = 1
        
        titleLabel.textColor = theme.primaryText
        descriptionLabel.textColor = theme.secondaryText
        descriptionLabel.numberOfLines = 2
        
        iconImageView.tintColor = theme.accentPrimary
    }
    
    func configure(item: PermissionItem, status: PermissionStatus, theme: AppTheme) {
        
        self.theme = theme
        
        setupUI()
        
        iconImageView.image = UIImage(systemName: item.icon)
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        
        switch status {
        case .authorized:
            statusLabel.text = "Allowed"
            statusLabel.textColor = UIColor(hex: "#2E7D32")
        case .denied:
            statusLabel.text = "Not Allowed"
            statusLabel.textColor = UIColor(hex: "#C62828")
        case .notDetermined:
            statusLabel.text = "Tap to Allow"
            statusLabel.textColor = UIColor(hex: "#EF6C00")
        }
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.containerView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }
    
}
