//
//  FAQCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 08/05/26.
//

import UIKit

class FAQCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var faqLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var answerTopConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        cardView.layer.cornerRadius = 18
        cardView.layer.borderWidth = 1
        cardView.clipsToBounds = true
        
        faqLabel.numberOfLines = 0
        answerLabel.numberOfLines = 0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        faqLabel.text = nil
        answerLabel.text = nil
        answerLabel.isHidden = true
        answerTopConstraint.constant = 0
    }
    
    func configure(icon: String, question: String, answer: String, isExpanded: Bool, theme: AppTheme) {
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = theme.accentPrimary
        
        faqLabel.text = question
        faqLabel.textColor = theme.primaryText
        
        answerLabel.text = isExpanded ? answer : nil
        answerLabel.textColor = theme.secondaryText
        answerLabel.isHidden = !isExpanded
        answerTopConstraint.constant = isExpanded ? 12 : 0
        
        cardView.backgroundColor = isExpanded ? theme.glassThin : theme.glassMedium
        cardView.layer.borderColor = theme.glassBorderLight.cgColor
    }
}
