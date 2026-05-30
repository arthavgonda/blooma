import UIKit

struct ProgressActivityData {
    let category:  String
    let name:      String
    let value:     Double
    let unit:      String
    let goal:      Double
    let goalUnit:  String
    let progress:  Double
    let color:     UIColor
    let imageName: String

    static func from(dataController: DataController, date: Date) -> [ProgressActivityData] {
        RoutineType.allCases.compactMap { type in
            let items = dataController.getRoutineItems(for: type, date: date)
            guard !items.isEmpty else { return nil }

            let total   = items.count
            let handled = items.filter {
                let p = dataController.loadProgress(for: $0, date: date)
                return p.status == .completed || p.status == .skipped
            }.count

            let fraction = Double(handled) / Double(total)

            switch type {
            case .walking:
                return ProgressActivityData(
                    category: "MOVEMENT", name: "Walking",
                    value: Double(handled), unit: "done",
                    goal: Double(total),   goalUnit: "total",
                    progress: fraction,
                    color: type.accentColor,
                    imageName: "walk"
                )
            case .exercise:
                return ProgressActivityData(
                    category: "STRENGTH", name: "Exercise",
                    value: Double(handled), unit: "done",
                    goal: Double(total),   goalUnit: "total",
                    progress: fraction,
                    color: type.accentColor,
                    imageName: "excercise"
                )
            case .yoga:
                return ProgressActivityData(
                    category: "MINDFULNESS", name: "Yoga",
                    value: Double(handled), unit: "done",
                    goal: Double(total),   goalUnit: "total",
                    progress: fraction,
                    color: type.accentColor,
                    imageName: "yoga"
                )
            }
        }
    }
}

class ProgressCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var percentRow: UIView!
    @IBOutlet weak var horizontalStack: UIStackView!
    @IBOutlet weak var leftVerticalStack: UIStackView!
    @IBOutlet weak var horizontalStackInsideLeftVerticalStack: UIStackView!
    @IBOutlet weak var rightStreakView: UIView!
    @IBOutlet weak var stackInsideRightStreakView: UIStackView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var percentSignLabel: UILabel!
    @IBOutlet weak var overallLabel: UILabel!
    @IBOutlet weak var miniCardsContainer: UIView!
    @IBOutlet weak var motivationContainer: UIView!
    @IBOutlet weak var motivationLabel: UILabel!
    @IBOutlet weak var streakLabel: UILabel!
    @IBOutlet weak var streakSubLabel: UILabel!
    @IBOutlet weak var trackFillView: UIView!
    @IBOutlet weak var trackBgView: UIView!
    @IBOutlet weak var trackFillWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var motivationIconDot: UIView!
    @IBOutlet weak var miniCardsStackView: UIStackView!
    @IBOutlet weak var card1View: UIView!
    @IBOutlet weak var card1ImageView: UIImageView!
    @IBOutlet weak var card1ScrimView: UIView!
    @IBOutlet weak var card1CategoryLabel: UILabel!
    @IBOutlet weak var card1NameLabel: UILabel!
    @IBOutlet weak var card1ValueLabel: UILabel!
    @IBOutlet weak var card1GoalLabel: UILabel!
    @IBOutlet weak var card1TrackView: UIView!
    @IBOutlet weak var card1FillView: UIView!
    @IBOutlet weak var card1FillWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var trackContainer: UIView!
    @IBOutlet weak var card2View: UIView!
    @IBOutlet weak var card2ImageView: UIImageView!
    @IBOutlet weak var card2ScrimView: UIView!
    @IBOutlet weak var card2CategoryLabel: UILabel!
    @IBOutlet weak var card2NameLabel: UILabel!
    @IBOutlet weak var card2ValueLabel: UILabel!
    @IBOutlet weak var card2GoalLabel: UILabel!
    @IBOutlet weak var card2TrackView: UIView!
    @IBOutlet weak var card2FillView: UIView!
    @IBOutlet weak var card2FillWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var card3View: UIView!
    @IBOutlet weak var card3ImageView: UIImageView!
    @IBOutlet weak var card3ScrimView: UIView!
    @IBOutlet weak var card3CategoryLabel: UILabel!
    @IBOutlet weak var card3NameLabel: UILabel!
    @IBOutlet weak var card3ValueLabel: UILabel!
    @IBOutlet weak var card3GoalLabel: UILabel!
    @IBOutlet weak var card3TrackView: UIView!
    @IBOutlet weak var card3FillView: UIView!
    @IBOutlet weak var card3FillWidthConstraint: NSLayoutConstraint!

    var onMiniCardTapped: ((RoutineType) -> Void)?

    // MARK: - Private state

    private var trackGradientLayer:     CAGradientLayer?
    private var containerGradientLayer: CAGradientLayer?
    private var storedFraction:         CGFloat = 0
    private var cardScrimGradients:     [CAGradientLayer] = []
    private var didApplyInitialFill     = false
    private var storedActivities:       [RoutineType] = []
    private var theme:                  AppTheme?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerGradientLayer?.frame = mainContainer.bounds

        let totalW = trackBgView.bounds.width
        let h      = trackBgView.bounds.height

        if totalW > 0, h > 0 {
            trackGradientLayer?.frame = CGRect(x: 0, y: 0, width: totalW * storedFraction, height: h)

            if !didApplyInitialFill {
                didApplyInitialFill = true
                trackFillWidthConstraint.constant = totalW * storedFraction
                layoutIfNeeded()
            }
        }

        zip(cardScrimGradients, allCardScrimViews()).forEach { grad, scrim in
            grad.frame = scrim.bounds
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        didApplyInitialFill = false
        storedFraction = 0
        trackFillWidthConstraint.constant = 0
        allCardViews().forEach { $0.isHidden = true }
    }

    // MARK: - Helpers

    private func allCardViews() -> [UIView] {
        [card1View, card2View, card3View]
    }

    private func allCardScrimViews() -> [UIView] {
        [card1ScrimView, card2ScrimView, card3ScrimView]
    }

    // MARK: - Setup

    private func setupUI(theme: AppTheme) {
        let bgGrad = CAGradientLayer()
        bgGrad.colors     = [theme.backgroundGradientStart.cgColor, theme.backgroundGradientEnd.cgColor]
        bgGrad.startPoint = CGPoint(x: 0, y: 0)
        bgGrad.endPoint   = CGPoint(x: 1, y: 1)

        containerGradientLayer?.removeFromSuperlayer()
        mainContainer.layer.insertSublayer(bgGrad, at: 0)
        containerGradientLayer = bgGrad

        mainContainer.backgroundColor    = .clear
        mainContainer.layer.cornerRadius = 24
        mainContainer.layer.cornerCurve  = .continuous
        mainContainer.clipsToBounds      = true
        mainContainer.layer.borderWidth  = 1.2
        mainContainer.layer.borderColor  = theme.glassBorderStrong.cgColor

        layer.shadowColor   = theme.shadowSoft.cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius  = 16
        layer.shadowOffset  = CGSize(width: 0, height: 4)
        layer.masksToBounds = false

        stack.axis         = .vertical
        stack.spacing      = 14
        stack.distribution = .fill
        stack.alignment    = .fill

        percentRow.backgroundColor = .clear

        horizontalStack.axis         = .horizontal
        horizontalStack.alignment    = .center
        horizontalStack.distribution = .fill

        leftVerticalStack.axis      = .vertical
        leftVerticalStack.spacing   = 2
        leftVerticalStack.alignment = .leading

        horizontalStackInsideLeftVerticalStack.axis      = .horizontal
        horizontalStackInsideLeftVerticalStack.spacing   = 2
        horizontalStackInsideLeftVerticalStack.alignment = .firstBaseline

        percentLabel.font      = UIFont.systemFont(ofSize: 52, weight: .bold)
        percentLabel.textColor = theme.primaryText

        percentSignLabel.font      = UIFont.systemFont(ofSize: 18, weight: .semibold)
        percentSignLabel.textColor = theme.accentPrimary

        overallLabel.font      = UIFont.systemFont(ofSize: 13, weight: .regular)
        overallLabel.textColor = theme.secondaryText

        rightStreakView.backgroundColor    = theme.glassMedium
        rightStreakView.layer.cornerRadius = 14
        rightStreakView.layer.cornerCurve  = .continuous
        rightStreakView.layer.borderWidth  = 1
        rightStreakView.layer.borderColor  = theme.glassBorderStrong.cgColor
        rightStreakView.setContentHuggingPriority(.required, for: .horizontal)
        rightStreakView.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightStreakView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        rightStreakView.widthAnchor.constraint(lessThanOrEqualToConstant: 120).isActive   = true

        stackInsideRightStreakView.axis      = .vertical
        stackInsideRightStreakView.spacing   = 2
        stackInsideRightStreakView.alignment = .center

        streakLabel.font          = UIFont.systemFont(ofSize: 22, weight: .bold)
        streakLabel.textColor     = theme.accentSecondary
        streakLabel.textAlignment = .center

        streakSubLabel.font          = UIFont.systemFont(ofSize: 11, weight: .medium)
        streakSubLabel.textColor     = theme.accentPrimary
        streakSubLabel.textAlignment = .center

        trackBgView.backgroundColor    = theme.accentPrimary.withAlphaComponent(0.18)
        trackBgView.layer.cornerRadius = 5
        trackBgView.clipsToBounds      = true
        trackBgView.layer.borderWidth  = 0

        trackFillView.backgroundColor    = .clear
        trackFillView.layer.cornerRadius = 5
        trackFillView.clipsToBounds      = false

        trackGradientLayer?.removeFromSuperlayer()
        let trackGrad = CAGradientLayer()
        trackGrad.colors       = [theme.accentPrimary.cgColor, theme.accentSecondary.cgColor]
        trackGrad.startPoint   = CGPoint(x: 0, y: 0.5)
        trackGrad.endPoint     = CGPoint(x: 1, y: 0.5)
        trackGrad.cornerRadius = 5
        trackFillView.layer.insertSublayer(trackGrad, at: 0)
        trackGradientLayer = trackGrad

        separatorView.backgroundColor = theme.divider

//        motivationContainer.backgroundColor    = theme.glassMedium
//        motivationContainer.layer.cornerRadius = 14
//        motivationContainer.layer.cornerCurve  = .continuous
//        motivationContainer.clipsToBounds      = true
//        motivationContainer.layer.borderWidth  = 1
//        motivationContainer.layer.borderColor  = theme.glassBorderStrong.cgColor
//        motivationContainer.setContentHuggingPriority(UILayoutPriority(252), for: .vertical)
//        motivationContainer.setContentCompressionResistancePriority(.required, for: .vertical)
        motivationContainer.backgroundColor = .clear

        motivationIconDot.backgroundColor    = theme.accentPrimary
        motivationIconDot.layer.cornerRadius = 7
        motivationIconDot.clipsToBounds      = true

        motivationLabel.font          = UIFont.systemFont(ofSize: 13.5, weight: .medium)
        motivationLabel.textColor     = theme.accentSecondary
        motivationLabel.numberOfLines = 0
        motivationLabel.setContentHuggingPriority(UILayoutPriority(252), for: .vertical)
        motivationLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        miniCardsContainer.setContentHuggingPriority(UILayoutPriority(249), for: .vertical)

        miniCardsStackView.axis         = .horizontal
        miniCardsStackView.spacing      = 10
        miniCardsStackView.distribution = .fillEqually
        miniCardsStackView.alignment    = .fill
    }

    private func setupCards(theme: AppTheme) {
        allCardViews().forEach { card in
            card.layer.cornerRadius = 18
            card.layer.cornerCurve  = .continuous
            card.clipsToBounds      = true
            card.isHidden           = true
            card.layer.borderWidth  = 1
            card.layer.borderColor  = theme.glassBorderLight.cgColor
        }

        [card1ImageView, card2ImageView, card3ImageView].forEach {
            $0?.contentMode   = .scaleAspectFill
            $0?.clipsToBounds = true
        }

        [card1TrackView, card2TrackView, card3TrackView].forEach { track in
            track?.backgroundColor    = UIColor.white.withAlphaComponent(0.25)
            track?.layer.cornerRadius = 2
            track?.clipsToBounds      = true
        }

        [card1FillView, card2FillView, card3FillView].forEach { fill in
            fill?.layer.cornerRadius = 2
            fill?.clipsToBounds      = true
        }

        [card1ValueLabel, card2ValueLabel, card3ValueLabel].forEach { label in
            label?.font                      = .systemFont(ofSize: 22, weight: .black)
            label?.textColor                 = .white
            label?.adjustsFontSizeToFitWidth = true
            label?.minimumScaleFactor        = 0.65
        }

        [card1NameLabel, card2NameLabel, card3NameLabel].forEach { label in
            label?.font      = .systemFont(ofSize: 13, weight: .bold)
            label?.textColor = .white
        }

        [card1CategoryLabel, card2CategoryLabel, card3CategoryLabel].forEach { label in
            label?.font      = .systemFont(ofSize: 8, weight: .bold)
            label?.textColor = UIColor.white.withAlphaComponent(0.75)
        }

        [card1GoalLabel, card2GoalLabel, card3GoalLabel].forEach { label in
            label?.font      = .systemFont(ofSize: 10, weight: .regular)
            label?.textColor = UIColor.white.withAlphaComponent(0.60)
        }

        cardScrimGradients.forEach { $0.removeFromSuperlayer() }
        cardScrimGradients = allCardScrimViews().map { scrim in
            let g = CAGradientLayer()
            g.colors    = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.04).cgColor,
                UIColor.black.withAlphaComponent(0.42).cgColor
            ]
            g.locations = [0.0, 0.50, 1.0]
            scrim.layer.insertSublayer(g, at: 0)
            return g
        }
    }

    // MARK: - Configure

    func configure(dataController: DataController, date: Date = Date(), theme: AppTheme) {
        self.theme = theme
        setupUI(theme: theme)
        setupCards(theme: theme)

        let percent    = dataController.getOverallCompletionPercent(for: date)
        let streak     = dataController.getCurrentStreak()
        let motivation = dataController.getMotivationMessage()

        percentLabel.text     = "\(percent)"
        percentSignLabel.text = "%"
        overallLabel.text     = "overall complete"
        streakLabel.text      = "\(streak)"
        streakSubLabel.text   = "day streak"
        motivationLabel.text  = motivation
        storedFraction        = CGFloat(percent) / 100.0
        didApplyInitialFill   = false

        configureMiniCards(dataController: dataController, date: date)

        setNeedsLayout()
    }

    // MARK: - Mini cards

    private func configureMiniCards(dataController: DataController, date: Date) {
        let activities = ProgressActivityData.from(dataController: dataController, date: date)
        storedActivities = activities.prefix(3).map { activity -> RoutineType in
            switch activity.name.lowercased() {
            case "walking":  return .walking
            case "exercise": return .exercise
            default:         return .yoga
            }
        }

        let cards: [(
            view: UIView,
            imageView: UIImageView,
            categoryLabel: UILabel,
            nameLabel: UILabel,
            valueLabel: UILabel,
            goalLabel: UILabel,
            fillView: UIView,
            fillConstraint: NSLayoutConstraint
        )] = [
            (card1View, card1ImageView, card1CategoryLabel, card1NameLabel, card1ValueLabel, card1GoalLabel, card1FillView, card1FillWidthConstraint),
            (card2View, card2ImageView, card2CategoryLabel, card2NameLabel, card2ValueLabel, card2GoalLabel, card2FillView, card2FillWidthConstraint),
            (card3View, card3ImageView, card3CategoryLabel, card3NameLabel, card3ValueLabel, card3GoalLabel, card3FillView, card3FillWidthConstraint)
        ]

        allCardViews().forEach { $0.isHidden = true }

        for (index, activity) in activities.prefix(3).enumerated() {
            let card = cards[index]
            card.view.isHidden            = false
            card.imageView.image          = UIImage(named: activity.imageName)
            card.categoryLabel.text       = activity.category
            card.nameLabel.text           = activity.name
            card.valueLabel.text          = "\(formatValue(activity.value)) \(activity.unit)"
            card.goalLabel.text           = "of \(formatValue(activity.goal)) \(activity.goalUnit)"
            card.fillView.backgroundColor = activity.color

            let trackWidth               = card.fillView.superview?.bounds.width ?? 0
            card.fillConstraint.constant = trackWidth * activity.progress

            let tap = UITapGestureRecognizer(target: self, action: #selector(miniCardTapped(_:)))
            card.view.addGestureRecognizer(tap)
            card.view.tag = index
        }

        UIView.animate(withDuration: 0.5) { self.layoutIfNeeded() }
    }

    @objc private func miniCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let tappedType = storedActivities[view.tag]
        onMiniCardTapped?(tappedType)
    }

    // MARK: - Track animation

    func animateTrackFill() {
        let totalW = trackBgView.bounds.width
        guard totalW > 0 else { return }

        let targetWidth = totalW * storedFraction
        trackGradientLayer?.frame         = CGRect(x: 0, y: 0, width: targetWidth, height: trackBgView.bounds.height)
        trackFillWidthConstraint.constant = targetWidth
        didApplyInitialFill               = true

        UIView.animate(
            withDuration: 0.7,
            delay: 0.15,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .curveEaseOut
        ) {
            self.layoutIfNeeded()
        } completion: { _ in
            let finalW = self.trackBgView.bounds.width * self.storedFraction
            self.trackGradientLayer?.frame = CGRect(x: 0, y: 0, width: finalW, height: self.trackBgView.bounds.height)
        }
    }

    // MARK: - Helpers

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}
