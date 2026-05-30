//
//  HeaderCardCell.swift
//  prenatalPregnancy
//
//  Created by Amandeep on 26/03/26.
//

import UIKit

class HeaderCardCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView : UIImageView?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 24
        containerView.backgroundColor = .clear
        setupUI()
    }
    
    private func setupUI() {
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.numberOfLines = 0
    }
    
    func configure(title: String, subtitle: String, icon: UIImage?, accentColor: UIColor, theme: AppTheme) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        imageView?.image = icon
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.shadowOpacity = 0
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        titleLabel.textColor = accentColor.withAlphaComponent(0.85)
        subtitleLabel.textColor = accentColor
        imageView?.tintColor = accentColor
    }
}
