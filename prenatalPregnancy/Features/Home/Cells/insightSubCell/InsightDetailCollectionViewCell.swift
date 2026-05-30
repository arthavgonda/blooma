import UIKit

// MARK: - Cell Identifiers
private enum CellID {
    static let description   = "InsightDescriptionCollectionViewCell"
    static let sectionHeader = "InsightSectionHeaderCollectionViewCell"
    static let item          = "InsightItemRowCollectionViewCell"
}

// MARK: - InsightRow
enum InsightRow {
    case description(String, InsightDescriptionStyle)
    case sectionHeader(title: String)
    case item(text: String, position: InsightItemPosition)
}

enum InsightItemPosition {
    case only, first, middle, last
}

// MARK: - InsightDetailCollectionViewCell
class InsightDetailCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var heroImage: UIImageView!
    @IBOutlet weak var blob1View: UIView!
    @IBOutlet weak var blob2View: UIView!
    @IBOutlet weak var heroOverLay: UIView!
    @IBOutlet weak var weekPillLabel: UILabel!
    @IBOutlet weak var sectionTagLabel: UILabel!
    @IBOutlet weak var heroTitleLabel: UILabel!
    @IBOutlet weak var heroSubtitleLabel: UILabel!
    @IBOutlet weak var grabberView: UIView!
    @IBOutlet weak var mainCard: UIView!
    @IBOutlet weak var sectionsTableView: UICollectionView!

    private var rows: [InsightRow] = []
    private var theme: AppTheme?
    private let clayRadius: CGFloat = 28
    private var cardHeightConstraint: NSLayoutConstraint?
    private var tableCornerMask: CAShapeLayer?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyles()
        setupCollectionView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        heroOverLay.frame = heroImage.bounds
        applyHeroOverlay()
        applyCollectionCornerMask()
    }

    // MARK: - Styles

    private func setupStyles() {
        heroImage.contentMode         = .scaleAspectFill
        heroImage.clipsToBounds       = true
        heroImage.layer.cornerRadius  = 12
        heroImage.layer.cornerCurve   = .continuous
        heroImage.layer.masksToBounds = true
        heroImage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        blob1View.isHidden = true
        blob2View.isHidden = true

        weekPillLabel.font                = .systemFont(ofSize: 11, weight: .semibold)
        weekPillLabel.textColor           = .white
        weekPillLabel.textAlignment       = .center
        weekPillLabel.backgroundColor     = UIColor.white.withAlphaComponent(0.22)
        weekPillLabel.layer.cornerRadius  = 6
        weekPillLabel.layer.masksToBounds = true
        weekPillLabel.layer.borderWidth   = 1
        weekPillLabel.layer.borderColor   = UIColor.white.withAlphaComponent(0.35).cgColor

        sectionTagLabel.font      = .systemFont(ofSize: 11, weight: .semibold)
        sectionTagLabel.textColor = UIColor.white.withAlphaComponent(0.80)

        heroTitleLabel.font                      = .systemFont(ofSize: 30, weight: .bold)
        heroTitleLabel.textColor                 = .white
        heroTitleLabel.numberOfLines             = 2
        heroTitleLabel.adjustsFontSizeToFitWidth = true
        heroTitleLabel.minimumScaleFactor        = 0.78

        heroSubtitleLabel.font          = .systemFont(ofSize: 13, weight: .regular)
        heroSubtitleLabel.textColor     = UIColor.white.withAlphaComponent(0.82)
        heroSubtitleLabel.numberOfLines = 2

        grabberView.backgroundColor    = UIColor(hex: "#C96A86").withAlphaComponent(0.35)
        grabberView.layer.cornerRadius = 2.5

        mainCard.backgroundColor     = UIColor(hex: "#F3E8EE")
        mainCard.layer.cornerRadius  = clayRadius
        mainCard.layer.cornerCurve   = .continuous
        mainCard.layer.masksToBounds = false
        mainCard.layer.borderWidth   = 1
        mainCard.layer.borderColor   = UIColor.white.withAlphaComponent(0.4).cgColor  // glassBorderLight
        mainCard.layer.shadowColor   = UIColor.black.cgColor
        mainCard.layer.shadowOpacity = 0.07
        mainCard.layer.shadowRadius  = 16
        mainCard.layer.shadowOffset  = CGSize(width: 0, height: 8)
    }

    private func applyCollectionCornerMask() {
        let path = UIBezierPath(
            roundedRect: sectionsTableView.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: clayRadius, height: clayRadius)
        )
        if tableCornerMask == nil {
            let mask = CAShapeLayer()
            sectionsTableView.layer.mask = mask
            tableCornerMask = mask
        }
        tableCornerMask?.path = path.cgPath
    }

    private func applyHeroOverlay() {
        heroOverLay.layer.sublayers?
            .filter { $0.name == "heroOverlay" }
            .forEach { $0.removeFromSuperlayer() }

        let grad = CAGradientLayer()
        grad.name     = "heroOverlay"
        grad.colors   = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.06).cgColor,
            UIColor.black.withAlphaComponent(0.62).cgColor
        ]
        grad.locations  = [0.0, 0.40, 1.0]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        grad.frame      = heroOverLay.bounds
        heroOverLay.layer.insertSublayer(grad, at: 0)
    }

    // MARK: - CollectionView Setup

    private func setupCollectionView() {
        sectionsTableView.backgroundColor              = .clear
        sectionsTableView.backgroundView               = nil
        sectionsTableView.isScrollEnabled              = false
        sectionsTableView.showsVerticalScrollIndicator = false
        sectionsTableView.delegate                     = self
        sectionsTableView.dataSource                   = self
        sectionsTableView.contentInset                 = UIEdgeInsets(top: 16, left: 0, bottom: 60, right: 0)

        sectionsTableView.register(
            UINib(nibName: CellID.description, bundle: nil),
            forCellWithReuseIdentifier: CellID.description)
        sectionsTableView.register(
            UINib(nibName: CellID.sectionHeader, bundle: nil),
            forCellWithReuseIdentifier: CellID.sectionHeader)
        sectionsTableView.register(
            UINib(nibName: CellID.item, bundle: nil),
            forCellWithReuseIdentifier: CellID.item)

        sectionsTableView.collectionViewLayout = makeLayout()
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self, sectionIndex < self.rows.count else { return nil }

            switch self.rows[sectionIndex] {

            case .description:
                let size  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(80))
                let item  = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)
                return section

            case .sectionHeader:
                let size  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(36))
                let item  = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 6, trailing: 16)
                return section

            case .item:
                let size  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(52))
                let item  = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                return section
            }
        }
    }

    // MARK: - Configure

    func configure(with detail: InsightDetail, category: Category, theme: AppTheme) {
        self.theme = theme

        heroImage.image        = UIImage(named: category.heroImage)
        weekPillLabel.text     = "  Week \(detail.week)  "
        sectionTagLabel.text   = sectionTag(for: detail.section)
        heroTitleLabel.text    = detail.title
        heroSubtitleLabel.text = detail.subtitle

        rows = buildRows(from: detail)
        sectionsTableView.reloadData()

        cardHeightConstraint?.isActive = false
        cardHeightConstraint = nil

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.sectionsTableView.layoutIfNeeded()

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let height = self.sectionsTableView.contentSize.height
                guard height > 0 else { return }

                let c = self.mainCard.heightAnchor.constraint(equalToConstant: height + 32)
                c.priority = UILayoutPriority(999)
                c.isActive = true
                self.cardHeightConstraint = c

                self.setNeedsLayout()
                self.layoutIfNeeded()
                self.applyCollectionCornerMask()

                if let cv = self.superview as? UICollectionView {
                    cv.collectionViewLayout.invalidateLayout()
                }
            }
        }
    }

    // MARK: - Row Builder

    private func buildRows(from detail: InsightDetail) -> [InsightRow] {
        var rows: [InsightRow] = []

        rows.append(.description(detail.description, .hero))

        let sections: [(String, [String]?)] = [
            ("What to expect",    detail.whatToExpect),
            ("Care tips",         detail.careTips),
            ("Nutrition focus",   detail.nutritionFocus),
            ("Recommended foods", detail.recommendedFoods),
            ("Foods to limit",    detail.foodsToLimit),
            ("Hydration",         detail.hydration),
            ("Rest practices",    detail.restPractices),
            ("Mindfulness",       detail.mindfulnessPractices),
            ("Emotional health",  detail.emotionalWellbeing),
            ("Daily safety",      detail.dailySafetyTips),
            ("Movement",          detail.movementGuidelines),
            ("Environment",       detail.environmentalAwareness),
            ("Travel safety",     detail.travelSafety),
        ]

        for (title, items) in sections {
            guard let items, !items.isEmpty else { continue }
            rows.append(.sectionHeader(title: title))
            for (idx, text) in items.enumerated() {
                rows.append(.item(text: text, position: position(idx: idx, count: items.count)))
            }
        }

        if let checkups = detail.medicalCheckups, !checkups.commonlySuggested.isEmpty {
            rows.append(.sectionHeader(title: "Medical checkups"))
            let items = checkups.commonlySuggested
            for (idx, c) in items.enumerated() {
                rows.append(.item(
                    text: "\(c.name) — \(c.purpose)",
                    position: position(idx: idx, count: items.count)
                ))
            }
        }

        if let reassurance = detail.reassurance {
            rows.append(.sectionHeader(title: "A note for you"))
            rows.append(.item(text: reassurance, position: .only))
        }

        if let disclaimer = detail.medicalDisclaimer {
            rows.append(.sectionHeader(title: "Medical disclaimer"))
            rows.append(.item(text: disclaimer, position: .only))
        }

        return rows
    }

    private func position(idx: Int, count: Int) -> InsightItemPosition {
        if count == 1       { return .only   }
        if idx == 0         { return .first  }
        if idx == count - 1 { return .last   }
        return .middle
    }

    private func sectionTag(for section: String) -> String {
        switch section {
        case "bump_care":            return "Wellness · Movement"
        case "strength_from_within": return "Strength · Fitness"
        case "rest_mindfulness":     return "Rest · Mindfulness"
        case "safety_awareness":     return "Safety · Awareness"
        default:                     return "Pregnancy care"
        }
    }
}

// MARK: - DataSource

extension InsightDetailCollectionViewCell: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        rows.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let theme else { return UICollectionViewCell() }

        switch rows[indexPath.section] {

        case .description(let text, let style):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellID.description, for: indexPath
            ) as! InsightDescriptionCollectionViewCell
            cell.configure(text: text, theme: theme, style: style)
            return cell

        case .sectionHeader(let title):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellID.sectionHeader, for: indexPath
            ) as! InsightSectionHeaderCollectionViewCell
            cell.configure(title: title, theme: theme)
            return cell

        case .item(let text, let position):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellID.item, for: indexPath
            ) as! InsightItemRowCollectionViewCell
            cell.configure(text: text, theme: theme, position: position)
            return cell
        }
    }
}

// MARK: - Delegate
extension InsightDetailCollectionViewCell: UICollectionViewDelegate {}
