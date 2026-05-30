//
//  ContentIntroCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 10/04/26.
//

import UIKit

class ContentIntroCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    private var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        
        bodyLabel.numberOfLines = 0
        headingLabel.numberOfLines = 0
        
        // Initialization code
    }
    
    func configure(section: String?, heading: String, body: String, theme: AppTheme) {
        self.theme = theme
        
        sectionLabel.text = section
        headingLabel.text = heading
        bodyLabel.text = body
        
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        
        sectionLabel.textColor = theme.accentSecondary
        
        headingLabel.textColor = theme.primaryText
        
        bodyLabel.textColor = theme.secondaryText
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        bodyLabel.attributedText = NSAttributedString(string: body, attributes: [.paragraphStyle: paragraphStyle])
    }
}
