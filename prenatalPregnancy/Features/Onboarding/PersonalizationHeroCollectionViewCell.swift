import UIKit

final class PersonalizationHeroCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var cardContainer: UIVisualEffectView!
    @IBOutlet private weak var illustrationContainer: UIView!
    @IBOutlet private weak var eyebrowLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var illustrationImageView: UIImageView!
    @IBOutlet private weak var heartImageView: UIImageView!
    @IBOutlet private weak var sparkleImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        contentView.clipsToBounds = false
        configureStaticCopy()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowRect = cardContainer.frame
        contentView.layer.shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: 30).cgPath
    }
    
    func configure(theme: AppTheme, isComplete: Bool) {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        cardContainer.contentView.backgroundColor = theme.glassThin
        cardContainer.layer.borderColor = theme.glassBorderStrong.cgColor
        contentView.layer.shadowColor = theme.shadowMedium.cgColor
        
        illustrationContainer.backgroundColor = UIColor.white.withAlphaComponent(0.34)
        illustrationContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.72).cgColor
        
        eyebrowLabel.textColor = theme.accentSecondary
        titleLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.secondaryText
        descriptionLabel.textColor = theme.secondaryText
        heartImageView.tintColor = theme.accentPrimary.withAlphaComponent(0.36)
        sparkleImageView.tintColor = theme.accentSecondary.withAlphaComponent(0.44)
        
        titleLabel.text = isComplete ? PersonalizationFlowContent.Hero.completeTitle : PersonalizationFlowContent.Hero.title
        subtitleLabel.text = isComplete ? PersonalizationFlowContent.Hero.completeSubtitle : PersonalizationFlowContent.Hero.subtitle
        descriptionLabel.text = isComplete ? PersonalizationFlowContent.Hero.completeDescription : PersonalizationFlowContent.Hero.description
        
        illustrationImageView.tintColor = theme.accentPrimary
    }
    
    private func configureStaticCopy() {
        cardContainer.layer.cornerRadius = 30
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.borderWidth = 1
        cardContainer.effect = UIBlurEffect(style: .systemThinMaterialLight)
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 22
        contentView.layer.shadowOffset = CGSize(width: 0, height: 14)
        cardContainer.clipsToBounds = true
        cardContainer.layer.masksToBounds = true
        cardContainer.contentView.layer.cornerRadius = 30
        cardContainer.contentView.layer.cornerCurve = .continuous
        cardContainer.contentView.clipsToBounds = true
        
        illustrationContainer.layer.cornerRadius = 34
        illustrationContainer.layer.cornerCurve = .continuous
        illustrationContainer.layer.borderWidth = 1
        illustrationContainer.clipsToBounds = true
        
        eyebrowLabel.text = PersonalizationFlowContent.Hero.eyebrow
        illustrationImageView.image = UIImage(systemName: PersonalizationFlowContent.Hero.illustrationIcon)
        heartImageView.image = UIImage(systemName: "heart.fill")
        sparkleImageView.image = UIImage(systemName: "sparkles")
    }
}
