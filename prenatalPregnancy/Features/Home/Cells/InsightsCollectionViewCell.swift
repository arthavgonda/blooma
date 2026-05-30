import UIKit

class InsightsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var insightImageView: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var badgeView: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var topScrimView: UIView!
    @IBOutlet weak var bottomScrimView: UIView!

    private let bottomScrimLayer = CAGradientLayer()
    private let topScrimLayer    = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        buildUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bottomScrimLayer.frame = contentView.bounds
        topScrimLayer.frame    = contentView.bounds
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: contentView.layer.cornerRadius
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        insightImageView.image = nil
        label.text             = nil
        subtitleLabel.text     = nil
        categoryLabel.text     = nil
        subtitleLabel.isHidden = true
    }

    func configure(with model: Insights, isHero: Bool) {
        insightImageView.image = model.image
        label.text             = model.title
        categoryLabel.text     = categoryTag(for: model.title)

        if isHero {
            contentView.layer.cornerRadius = 20
            layer.shadowOpacity            = 0.15
            layer.shadowRadius             = 16
            label.font                     = .systemFont(ofSize: 22, weight: .heavy)
            categoryLabel.font             = .systemFont(ofSize: 11, weight: .semibold)
            subtitleLabel.text             = model.description.isEmpty ? nil : model.description
            subtitleLabel.isHidden         = model.description.isEmpty
            badgeLabel.text                = "✦  Featured"
            badgeView.isHidden             = false
            bottomScrimLayer.colors        = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.20).cgColor,
                UIColor.black.withAlphaComponent(0.48).cgColor
            ]
            bottomScrimLayer.locations = [0.28, 0.55, 1.0]
        } else {
            contentView.layer.cornerRadius = 16
            layer.shadowOpacity            = 0.15
            layer.shadowRadius             = 10
            label.font                     = .systemFont(ofSize: 13, weight: .heavy)
            categoryLabel.font             = .systemFont(ofSize: 9, weight: .semibold)
            subtitleLabel.isHidden         = true
            badgeLabel.text                = "✦"
            badgeView.isHidden             = false
            bottomScrimLayer.colors        = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.30).cgColor,
                UIColor.black.withAlphaComponent(0.32).cgColor
            ]
            bottomScrimLayer.locations = [0.05, 0.42, 1.0]
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func buildUI() {
        layer.masksToBounds = false
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOffset  = CGSize(width: 0, height: 5)
        layer.shadowOpacity = 0
        layer.shadowRadius  = 12

        contentView.clipsToBounds      = true
        contentView.layer.cornerRadius = 20

        insightImageView.contentMode   = .scaleAspectFill
        insightImageView.clipsToBounds = false

        topScrimLayer.colors     = [UIColor.black.withAlphaComponent(0.18).cgColor, UIColor.clear.cgColor]
        topScrimLayer.locations  = [0, 0.28]
        topScrimLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topScrimLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        topScrimView.layer.addSublayer(topScrimLayer)
        topScrimView.isUserInteractionEnabled = false

        bottomScrimLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomScrimLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        bottomScrimView.layer.addSublayer(bottomScrimLayer)
        bottomScrimView.isUserInteractionEnabled = false

        badgeView.backgroundColor    = UIColor.white.withAlphaComponent(0.22)
        badgeView.layer.cornerRadius = 10
        badgeView.layer.borderWidth  = 1
        badgeView.layer.borderColor  = UIColor.white.withAlphaComponent(0.35).cgColor
        badgeView.clipsToBounds = false
        badgeView.layer.masksToBounds = true

        badgeLabel.font      = .systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = UIColor.white.withAlphaComponent(0.95)

        categoryLabel.textColor     = UIColor.white
        categoryLabel.numberOfLines = 1

        label.textColor           = .white
        label.numberOfLines       = 2
        label.lineBreakMode       = .byTruncatingTail
        label.layer.shadowColor   = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.6
        label.layer.shadowRadius  = 6
        label.layer.shadowOffset  = CGSize(width: 0, height: 1)
        label.layer.masksToBounds = false
        label.layer.opacity = 0.7

        subtitleLabel.textColor     = UIColor.white
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.font          = .systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.isHidden      = true
    }

    private func categoryTag(for title: String) -> String {
        let t = title.lowercased()
        if t.contains("bump")                         { return "Wellness · Movement" }
        if t.contains("calm") || t.contains("sleep")  { return "Rest · Mindfulness"  }
        if t.contains("strength")                     { return "Strength · Fitness"  }
        if t.contains("safe") || t.contains("moment") { return "Safety · Awareness"  }
        return "This Week"
    }
}
