import UIKit

final class PersonalizationProgressCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var cardContainer: UIVisualEffectView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var stepLabel: UILabel!
    @IBOutlet private weak var percentLabel: UILabel!
    @IBOutlet private weak var progressTrackView: UIView!
    @IBOutlet private weak var progressFillView: UIView!
    @IBOutlet private weak var progressFillWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        contentView.clipsToBounds = false
        configureStaticStyle()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(roundedRect: cardContainer.frame, cornerRadius: 24).cgPath
    }
    
    func configure(stepIndex: Int, totalSteps: Int, progress: CGFloat, theme: AppTheme, animated: Bool) {
        let clampedProgress = min(max(progress, 0), 1)
        
        titleLabel.text = PersonalizationFlowContent.Progress.title
        stepLabel.text = PersonalizationFlowContent.Progress.stepText(current: stepIndex, total: totalSteps)
        percentLabel.text = PersonalizationFlowContent.Progress.percentText(progress: clampedProgress)
        
        titleLabel.textColor = theme.primaryText
        stepLabel.textColor = theme.secondaryText
        percentLabel.textColor = theme.accentSecondary
        cardContainer.contentView.backgroundColor = theme.glassThin
        cardContainer.layer.borderColor = theme.glassBorderStrong.cgColor
        contentView.layer.shadowColor = theme.shadowSoft.cgColor
        progressTrackView.backgroundColor = UIColor.white.withAlphaComponent(0.46)
        progressFillView.backgroundColor = theme.accentSecondary
        
        layoutIfNeeded()
        progressFillWidthConstraint.constant = progressTrackView.bounds.width * clampedProgress
        
        guard animated else {
            layoutIfNeeded()
            return
        }
        
        UIView.animate(withDuration: 0.54, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4, options: [.allowUserInteraction]) {
            self.layoutIfNeeded()
        }
    }
    
    private func configureStaticStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        cardContainer.layer.cornerRadius = 24
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.borderWidth = 1
        cardContainer.effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 14
        contentView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardContainer.clipsToBounds = true
        cardContainer.layer.masksToBounds = true
        cardContainer.contentView.layer.cornerRadius = 24
        cardContainer.contentView.layer.cornerCurve = .continuous
        cardContainer.contentView.clipsToBounds = true
        
        progressTrackView.layer.cornerRadius = 7
        progressTrackView.layer.cornerCurve = .continuous
        progressTrackView.clipsToBounds = true
        progressFillView.layer.cornerRadius = 7
        progressFillView.layer.cornerCurve = .continuous
    }
}
