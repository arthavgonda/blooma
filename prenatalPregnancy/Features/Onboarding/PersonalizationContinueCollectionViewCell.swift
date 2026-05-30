import UIKit

final class PersonalizationContinueCollectionViewCell: UICollectionViewCell {
    
    var onContinueTapped: (() -> Void)?
    
    @IBOutlet private weak var cardContainer: UIVisualEffectView!
    @IBOutlet private weak var continueButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        contentView.clipsToBounds = false
        configureStaticStyle()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onContinueTapped = nil
        continueButton.transform = .identity
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(roundedRect: cardContainer.frame, cornerRadius: 28).cgPath
    }
    
    func configure(theme: AppTheme) {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardContainer.contentView.backgroundColor = theme.glassThin
        cardContainer.layer.borderColor = theme.glassBorderStrong.cgColor
        contentView.layer.shadowColor = theme.shadowMedium.cgColor
        continueButton.backgroundColor = theme.accentSecondary
        continueButton.tintColor = .white
        continueButton.setTitle(PersonalizationFlowContent.Continue.title, for: .normal)
        continueButton.setImage(UIImage(systemName: PersonalizationFlowContent.Continue.icon), for: .normal)
        continueButton.semanticContentAttribute = .forceRightToLeft
        continueButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: -12)
    }
    
    private func configureStaticStyle() {
        cardContainer.layer.cornerRadius = 28
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.borderWidth = 1
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 18
        contentView.layer.shadowOffset = CGSize(width: 0, height: 10)
        cardContainer.clipsToBounds = true
        cardContainer.layer.masksToBounds = true
        cardContainer.contentView.layer.cornerRadius = 28
        cardContainer.contentView.layer.cornerCurve = .continuous
        cardContainer.contentView.clipsToBounds = true
        
        continueButton.layer.cornerRadius = 25
        continueButton.layer.cornerCurve = .continuous
        continueButton.clipsToBounds = true
    }
    
    @IBAction private func continueTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.975, y: 0.975)
        }
    }
    
    @IBAction private func continueTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.24, delay: 0, usingSpringWithDamping: 0.74, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            sender.transform = .identity
        }
    }
    
    @IBAction private func continueTapped(_ sender: UIButton) {
        onContinueTapped?()
    }
}
