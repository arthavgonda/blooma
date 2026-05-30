import UIKit

final class PersonalizationStepsCollectionViewCell: UICollectionViewCell {
    
    enum State {
        case pending
        case active
        case complete
    }
    
    @IBOutlet private weak var cardContainer: UIVisualEffectView!
    @IBOutlet private weak var iconShellView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var stateImageView: UIImageView!
    
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
    
    func configure(step: RoutineProcessingStep, stepNumber: Int, state: State, theme: AppTheme, animated: Bool) {
        let display = PersonalizationFlowContent.display(for: step)
        titleLabel.text = display.title
        subtitleLabel.text = display.subtitle
        iconImageView.image = UIImage(systemName: display.iconName) ?? UIImage(systemName: display.fallbackIconName)
        
        titleLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.secondaryText
        iconShellView.backgroundColor = UIColor.white.withAlphaComponent(0.44)
        
        apply(state: state, theme: theme, animated: animated)
    }
    
    private func configureStaticStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        cardContainer.layer.cornerRadius = 24
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.borderWidth = 1
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 14
        contentView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardContainer.clipsToBounds = true
        cardContainer.layer.masksToBounds = true
        cardContainer.contentView.layer.cornerRadius = 24
        cardContainer.contentView.layer.cornerCurve = .continuous
        cardContainer.contentView.clipsToBounds = true
        
        iconShellView.layer.cornerRadius = 24
        iconShellView.layer.cornerCurve = .continuous
        iconShellView.clipsToBounds = true
    }
    
    private func apply(state: State, theme: AppTheme, animated: Bool) {
        let updates = {
            switch state {
            case .pending:
                self.cardContainer.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.26)
                self.cardContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.48).cgColor
                self.contentView.layer.shadowColor = theme.shadowSoft.cgColor
                self.iconImageView.tintColor = theme.tertiaryText.withAlphaComponent(0.45)
                self.stateImageView.image = UIImage(systemName: "circle")
                self.stateImageView.tintColor = theme.tertiaryText.withAlphaComponent(0.44)
                self.alpha = 0.64
                self.transform = .identity
            case .active:
                self.cardContainer.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.58)
                self.cardContainer.layer.borderColor = theme.accentPrimary.withAlphaComponent(0.86).cgColor
                self.contentView.layer.shadowColor = theme.shadowMedium.cgColor
                self.iconImageView.tintColor = theme.accentPrimary
                self.stateImageView.image = UIImage(systemName: "sparkle.magnifyingglass")
                self.stateImageView.tintColor = theme.accentSecondary
                self.alpha = 1
                self.transform = CGAffineTransform(scaleX: 1.012, y: 1.012)
            case .complete:
                self.cardContainer.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.42)
                self.cardContainer.layer.borderColor = UIColor(hex: "#9FE4C7", alpha: 0.9).cgColor
                self.contentView.layer.shadowColor = theme.shadowSoft.cgColor
                self.iconImageView.tintColor = theme.accentPrimary
                self.stateImageView.image = UIImage(systemName: "checkmark.circle.fill")
                self.stateImageView.tintColor = UIColor(hex: "#75CDAE")
                self.alpha = 0.9
                self.transform = .identity
            }
        }
        
        guard animated else {
            updates()
            return
        }
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.45, options: [.allowUserInteraction], animations: updates)
    }
    
}
