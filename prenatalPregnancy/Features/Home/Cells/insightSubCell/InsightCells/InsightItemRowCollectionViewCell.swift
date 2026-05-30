import UIKit

class InsightItemRowCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var text: UILabel!

    private let borderLayer = CAShapeLayer()
    private var position: InsightItemPosition = .only
    private let radius: CGFloat = 16

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        borderLayer.path = nil
    }

    private func setupUI(theme: AppTheme) {

        text.numberOfLines = 0
        text.font = .systemFont(ofSize: 14, weight: .regular)
        text.textColor = theme.primaryText

        // Exactly like ProfileMenuCollectionViewCell
        container.backgroundColor = theme.glassMedium
        container.layer.borderColor = theme.glassBorderLight.cgColor
        container.layer.borderWidth = 1
        container.layer.masksToBounds = true
        container.layer.shadowOpacity = 0

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1
        borderLayer.strokeColor = theme.glassBorderLight.cgColor
        borderLayer.contentsScale = traitCollection.displayScale

        if borderLayer.superlayer == nil {
            container.layer.addSublayer(borderLayer)
        }
    }

    func configure(text: String, theme: AppTheme, position: InsightItemPosition) {
        self.text.text = text
        self.position = position
        setupUI(theme: theme)
        applyCorners()
        container.layoutIfNeeded()
        drawBorder()
    }

    private func applyCorners() {
        container.layer.cornerRadius = 0
        container.layer.maskedCorners = []

        switch position {
        case .only:
            container.layer.cornerRadius = radius
            container.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        case .first:
            container.layer.cornerRadius = radius
            container.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner
            ]
        case .middle:
            break
        case .last:
            container.layer.cornerRadius = radius
            container.layer.maskedCorners = [
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        }
    }

    private func drawBorder() {
        guard container.bounds.width > 0 else { return }

        let w = container.bounds.width
        let h = container.bounds.height
        let r = radius
        let path = UIBezierPath()

        switch position {
        case .only:
            path.append(UIBezierPath(roundedRect: container.bounds, cornerRadius: r))

        case .first:
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addArc(withCenter: CGPoint(x: r, y: r), radius: r,
                        startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: w - r, y: 0))
            path.addArc(withCenter: CGPoint(x: w - r, y: r), radius: r,
                        startAngle: -.pi / 2, endAngle: 0, clockwise: true)
            path.addLine(to: CGPoint(x: w, y: h))
            // Bottom divider line
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w, y: h))

        case .middle:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: w, y: 0))

        case .last:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: h - r))
            path.addArc(withCenter: CGPoint(x: r, y: h - r), radius: r,
                        startAngle: .pi, endAngle: .pi / 2, clockwise: false)
            path.addLine(to: CGPoint(x: w - r, y: h))
            path.addArc(withCenter: CGPoint(x: w - r, y: h - r), radius: r,
                        startAngle: .pi / 2, endAngle: 0, clockwise: false)
            path.addLine(to: CGPoint(x: w, y: 0))
        }

        borderLayer.path = path.cgPath
    }
}
