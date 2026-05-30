//
//  ContentFeatureCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 10/04/26.
//

import UIKit

class ContentFeatureCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        containerView.layer.cornerRadius = 18
        containerView.layer.borderWidth = 1
        
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        descriptionLabel.numberOfLines = 0
        
        // Initialization code
    }
    
    func configure(icon: String, title: String, description: String, theme: AppTheme) {
        self.theme = theme
        
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = theme.accentPrimary
        
        titleLabel.text = title
        descriptionLabel.text = description
        
        titleLabel.textColor = theme.primaryText
        descriptionLabel.textColor = theme.secondaryText
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        
        descriptionLabel.attributedText = NSAttributedString(
            string: description,
            attributes: [
                .paragraphStyle: paragraphStyle
            ]
        )
        
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        containerView.layer.shadowColor = theme.shadowSoft.cgColor
    }
}
