import UIKit

enum InsightDescriptionStyle {
    case hero    // first cell — more padding
    case normal  // reused for disclaimer/reassurance
}

class InsightDescriptionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var content: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func configure(text: String, theme: AppTheme, style: InsightDescriptionStyle = .normal) {
        content.text = text
        content.textColor = theme.primaryText
        content.numberOfLines = 0
        content.font = .systemFont(ofSize: 15, weight: .regular)

        container.backgroundColor = theme.glassMedium
        container.layer.borderWidth = 1
        container.layer.borderColor = theme.glassBorderLight.cgColor
        container.layer.cornerRadius = 16
        container.layer.cornerCurve = .continuous
        container.layer.masksToBounds = true

        let padding: CGFloat = style == .hero ? 12 : 8
        content.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)

        // Update constraints
        content.constraints.forEach { $0.isActive = false }
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding)
        ])
    }
}
