//
//  RoutineCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 02/02/26.
//

import UIKit

class RoutineCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var footnoteLabel: UILabel!
    
    private var footnotes: [String] = []
    private var footnoteIndex: Int = 0
    private var footnoteTimer: Timer?
    
    var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        // Initialization code
    }
    
    func configureCell(routineType: RoutineType, completedItems: Int, totalItems: Int, footnote: [String], theme: AppTheme) {
        self.theme = theme
        titleLabel.text = routineType.displayTitle
        progressLabel.text = "\(completedItems) / \(totalItems) completed"
        
        let progress = totalItems == 0 ? 0 : Float(completedItems) / Float(totalItems)
        
        progressView.setProgress(progress, animated: true)
        applyTheme(for: routineType)
        self.footnotes = footnote
        footnoteIndex = 0
        footnoteLabel.text = footnotes.first ?? ""
        startFootnoteRotation()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        footnoteTimer?.invalidate()
        footnoteTimer = nil
        footnotes = []
        footnoteIndex = 0
    }
    
    private func startFootnoteRotation() {
        guard footnotes.count > 1 else { return }
        footnoteTimer?.invalidate()
        footnoteTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.footnoteIndex = (self.footnoteIndex + 1) % self.footnotes.count
            UIView.transition(with: self.footnoteLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.footnoteLabel.text = self.footnotes[self.footnoteIndex]
            })
        }
    }
    
    private func setupUI() {
        
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 1
        
        cardView.layer.shadowOpacity = 0
        
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        
        titleLabel.numberOfLines = 1
        progressLabel.numberOfLines = 1
        footnoteLabel.numberOfLines = 0
        
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        
        chevronImageView.image = UIImage(systemName: "chevron.right")
    }
    
    private func applyTheme(for routineType: RoutineType) {
        
        cardView.backgroundColor = theme.glassMedium
        cardView.layer.borderColor = theme.glassBorderLight.cgColor
        
        titleLabel.textColor = theme.primaryText
        progressLabel.textColor = theme.primaryText
        footnoteLabel.textColor = theme.secondaryText
        
        progressView.trackTintColor = theme.glassMedium
        
        chevronImageView.tintColor = theme.secondaryText
        
        iconImageView.image = UIImage(systemName: routineType.iconName)
        
        let accent = routineType.accentColor
        iconImageView.tintColor = accent
        progressView.progressTintColor = accent
        
    }

}
