//
//  RoutineHomeCollectionViewCell.swift
//  prenatalPregnancy
//

import UIKit

class RoutineHomeCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var activityImage: UIImageView!
    @IBOutlet weak var activity: UILabel!
    @IBOutlet weak var activityName: UILabel!
    @IBOutlet weak var levelContainer: UIView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var durationContainer: UIView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var trackBG: UIView!
    @IBOutlet weak var trackFill: UIView!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var trackProgressWidth: NSLayoutConstraint!
    @IBOutlet weak var bottomContainer: UIView!
    
    var dataController: DataController!
    private var currentItem: RoutineItem?
    private var currentAccent: UIColor = .systemBlue
    var theme: AppTheme!

    override func awakeFromNib() {
        super.awakeFromNib()
        activityImage.layer.cornerRadius = 16
        layer.cornerRadius = 16
        clipsToBounds = true
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        activityImage.image = nil
        activity.text = nil
        activityName.text = nil
        percentageLabel.text = "0%"
        trackProgressWidth.constant = 0
        trackFill.backgroundColor = .systemBlue
        currentItem = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        levelContainer.layer.cornerRadius = levelContainer.bounds.height / 2
        durationContainer.layer.cornerRadius = durationContainer.bounds.height / 2
        trackBG.layer.cornerRadius = trackBG.bounds.height / 2
        trackFill.layer.cornerRadius = trackFill.bounds.height / 2
        applyBottomFadeBackground(to: bottomContainer, color: .black)
    }

    // MARK: - Main Configure

    func configureCell(with item: RoutineItem, progress: RoutineItemProgress?, index: Int , theme : AppTheme) {
        self.theme = theme 
        bottomContainer.backgroundColor = .clear
        currentItem = item
        let accent = item.routineType.accentColor
        currentAccent = accent

        let difficultyLevel = dataController.mapDifficulty(item.difficulty)
        let diffColor = difficultyColor(for: difficultyLevel)

        // Activity image
        switch item.routineType.rawValue.lowercased() {
        case "yoga":
            activityImage.image = UIImage(named: "routineYoga")
        case "exercise", "excercise":
            activityImage.image = UIImage(named: "routineExcercise")
        case "walking", "walk":
            activityImage.image = UIImage(named: "routineWalk")
        default:
            activityImage.image = UIImage(named: "routineWalk")
        }

        // Labels
        activity.text = item.routineType.rawValue.capitalized
        activity.textColor = .black
        activity.layer.opacity = 0.5

        activityName.text = item.title
        activityName.textColor = .white
        activityName.layer.opacity = 0.7

        // Level badge
        levelLabel.text = difficultyLevel.rawValue.capitalized
        levelLabel.textColor = diffColor
        levelContainer.backgroundColor = diffColor.withAlphaComponent(0.12)
        levelContainer.layer.borderWidth = 1
        levelContainer.layer.borderColor = diffColor.withAlphaComponent(0.35).cgColor

        // Duration badge
        durationLabel.text = "\(item.durationSeconds / 60) min"
        durationLabel.textColor = .white
        durationContainer.backgroundColor = theme.glassThin.withAlphaComponent(0.12)
        durationContainer.layer.borderWidth = 1
        durationContainer.layer.borderColor = accent.withAlphaComponent(0.35).cgColor

        trackFill.backgroundColor = accent
        updateProgress(item: item, progress: progress, accent: accent, animated: false)
    }

    func refreshProgress(progress: RoutineItemProgress?) {
        guard let item = currentItem else { return }
        updateProgress(item: item, progress: progress, accent: currentAccent, animated: true)
    }


    private func updateProgress(item: RoutineItem, progress: RoutineItemProgress?, accent: UIColor, animated: Bool) {

        let totalSeconds = max(item.durationSeconds, 1)
        let elapsed = progress?.elapsedSeconds ?? 0
        let fraction = min(max(CGFloat(elapsed) / CGFloat(totalSeconds), 0), 1)
        let pct = Int(fraction * 100)

        if progress?.status == .completed {
            applyFill(fraction: 1.0, color: accent, animated: animated)
            percentageLabel.text = "Done"
            percentageLabel.textColor = accent
            return
        }

        if progress?.status == .skipped {
            applyFill(fraction: 1.0, color: .systemOrange, animated: animated)
            percentageLabel.text = "Skipped"
            percentageLabel.textColor = .systemOrange
            return
        }

        // In progress or not started
        applyFill(fraction: fraction, color: accent, animated: animated)
        percentageLabel.text = pct == 0 ? "0%" : "\(pct)%"
        percentageLabel.textColor = pct == 0 ? .white : accent
    }

    private func applyFill(fraction: CGFloat, color: UIColor, animated: Bool) {
        // Must layout first so trackBG.bounds.width is accurate
        trackBG.layoutIfNeeded()
        let maxWidth = trackBG.bounds.width
        let targetWidth = maxWidth * fraction

        trackFill.backgroundColor = color

        // Gradient overlay on fill
        applyGradient(to: trackFill, color: color)

        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
                self.trackProgressWidth.constant = targetWidth
                self.layoutIfNeeded()
            }
        } else {
            trackProgressWidth.constant = targetWidth
            layoutIfNeeded()
        }
    }

    private func applyGradient(to view: UIView, color: UIColor) {
        view.layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let grad = CAGradientLayer()
        grad.frame = view.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: trackBG.bounds.width, height: trackBG.bounds.height)
            : view.bounds
        grad.colors = [color.withAlphaComponent(0.6).cgColor, color.cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0.5)
        grad.endPoint   = CGPoint(x: 1, y: 0.5)
        view.layer.insertSublayer(grad, at: 0)
    }

    // MARK: - Helpers

    private func difficultyColor(for difficulty: DifficultyLevel) -> UIColor {
        switch difficulty {
        case .beginner:     return .systemGreen
        case .intermediate: return .systemOrange
        case .advanced:     return .systemRed
        }
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        
        // The cell itself needs clipping
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 16 // match your design
        
        // Bottom container masking
        bottomContainer.layer.cornerRadius = 16
        bottomContainer.clipsToBounds = true
//        bottomContainer.layer.masksToBounds = true

        activityImage.contentMode = .scaleAspectFill
        activityImage.clipsToBounds = true

        levelContainer.clipsToBounds = true
        durationContainer.clipsToBounds = true

        trackBG.backgroundColor = UIColor.systemGray5
        trackBG.clipsToBounds = true

        trackFill.clipsToBounds = true
    }
    
    private func applyBottomFadeBackground(to view: UIView, color: UIColor) {
        view.layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,                  // stay clear for first half
            color.withAlphaComponent(0.7).cgColor,
            color.withAlphaComponent(0.92).cgColor  // solid at very bottom
        ]
        gradient.locations = [0.0, 0.3, 0.7, 1.0]  // controls where fade begins
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradient, at: 0)
    }
}
