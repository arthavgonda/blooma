//
//  NotesCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 09/04/26.
//

import UIKit

class NotesCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(theme: AppTheme) {
        subtitleLabel.text = "Add extra feedback"
        subtitleLabel.textColor = theme.secondaryText

        textView.backgroundColor = theme.glassMedium
        textView.layer.cornerRadius = 16
        textView.layer.borderWidth = 1
        textView.layer.borderColor = theme.glassBorderLight.cgColor
    }
}
