//
//  DailyRoutineCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 02/02/26.
//

import UIKit

class DailyRoutineCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var clockIconImageView: UIImageView!
    @IBOutlet weak var durationValueLabel: UILabel!
    
    @IBOutlet weak var intensityOrRepsIconImageView: UIImageView!
    @IBOutlet weak var intensityOrRepsValueLabel: UILabel!
    
    @IBOutlet weak var difficultyView: UIView!
    @IBOutlet weak var difficultyLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressViewLabel: UILabel!
    
    @IBOutlet weak var chevronImageView: UIImageView!
    
    @IBOutlet var infoContainerViews: [UIView]!
    
    @IBOutlet weak var gradientOverlayView: UIView!
    
    var theme: AppTheme!
    var dataController: DataController!

    /// Tracks which image name this cell last requested so we can discard
    /// stale Cloudinary callbacks after the cell is reused.
    private var currentImageKey: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        progressView.progress = 0
        previewImageView.image = nil
        previewImageView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        currentImageKey = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        difficultyView.layer.cornerRadius = difficultyView.bounds.height / 2
        
        applyFullGradientOverlay()
    }
    
    func configureCell(with item: RoutineItem, progress: RoutineItemProgress?, index: Int, dataController: DataController) {
        
        self.dataController = dataController
        self.theme = dataController.theme
        
        let accent = item.routineType.accentColor
        let difficultyLevel = dataController.mapDifficulty(item.difficulty)
        let difficultyColor = difficultyColor(for: difficultyLevel)
        
        // Content
        titleLabel.text = item.title
        titleLabel.textColor = .white
        
        orderLabel.text = "\(index + 1)."
        orderLabel.textColor = .white
        
        // Show local asset instantly as placeholder, then upgrade to Cloudinary.
        let localFallback = resolvedImage(named: item.image, routineType: item.routineType)
        previewImageView.image = localFallback
        
        let requestedKey = item.image
        currentImageKey = requestedKey
        
        CloudinaryImageCache.shared.loadImage(
            named: item.image,
            routineType: item.routineType,
            fallback: localFallback
        ) { [weak self] image in
            guard let self, self.currentImageKey == requestedKey else { return }
            if let image {
                self.previewImageView.image = image
            }
        }
        
        // Icons
        clockIconImageView.image = UIImage(systemName: "clock.fill")
        clockIconImageView.tintColor = accent
        
        intensityOrRepsIconImageView.image = UIImage(systemName: item.routineType.iconName)
        intensityOrRepsIconImageView.tintColor = accent
        
        // Values
        durationValueLabel.text = "\(item.durationSeconds / 60) min"
        durationValueLabel.textColor = .white
        
        if item.routineType == .walking {
            intensityOrRepsValueLabel.text = item.distanceMeters != nil ? "\(item.distanceMeters!)" : "-"
        } else {
            intensityOrRepsValueLabel.text = item.reps != nil ? "\(item.reps!)" : "-"
        }
        intensityOrRepsValueLabel.textColor = .white
        
        // Difficulty
        difficultyLabel.text = difficultyLevel.rawValue.capitalized
        difficultyLabel.textColor = .white
        
        difficultyView.layer.borderWidth = 1
        difficultyView.layer.borderColor = difficultyColor.cgColor
        
        // Progress
        progressView.trackTintColor = theme.glassThin
        updateProgress(item: item, progress: progress, accent: accent)
        
        chevronImageView.tintColor = .white
        
        styleInfoContainers()
    }
    
    private func setupUI() {
        
        contentView.backgroundColor = .clear
        
        cardView.layer.cornerRadius = 20
        cardView.backgroundColor = theme?.glassMedium
        
        previewImageView.layer.cornerRadius = 20
        previewImageView.clipsToBounds = true
        previewImageView.isOpaque = true
        previewImageView.alpha = 1.0
        
        gradientOverlayView.clipsToBounds = true

        cardView.clipsToBounds = true
        
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
    }
    
    private func applyFullGradientOverlay() {
        
        gradientOverlayView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        let gradient = CAGradientLayer()
        gradient.frame = gradientOverlayView.bounds
        
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.05).cgColor,
            UIColor.black.withAlphaComponent(0.12).cgColor,
            UIColor.black.withAlphaComponent(0.18).cgColor
        ]
        
        gradient.locations = [0.0, 0.5, 0.75, 1.0]
        
        gradientOverlayView.layer.addSublayer(gradient)
    }
    
    private func styleInfoContainers() {
        
        infoContainerViews.forEach { view in
            
            view.layer.cornerRadius = 10
            view.clipsToBounds = true
            
            view.backgroundColor = theme.glassThin
            view.layer.borderWidth = 1
            view.layer.borderColor = theme.glassBorderLight.cgColor
        }
    }
    
    private func updateProgress(item: RoutineItem, progress: RoutineItemProgress?, accent: UIColor) {
        
        let totalSeconds = max(item.durationSeconds, 1)
        let elapsed = progress?.elapsedSeconds ?? 0
        
        let fraction = min(max(Float(elapsed) / Float(totalSeconds), 0), 1)
        
        progressView.progressTintColor = accent
        progressView.setProgress(fraction, animated: true)
        
        if progress?.status == .completed {
            progressViewLabel.text = "Done"
            progressView.setProgress(1.0, animated: true)
            return
        }
        
        if progress?.status == .skipped {
            progressViewLabel.text = "Skip"
            progressView.setProgress(0.0, animated: true)
            return
        }
        
        progressViewLabel.text = "\(Int(fraction * 100))%"
        progressViewLabel.textColor = .white
    }
    
    private func difficultyColor(for difficulty: DifficultyLevel) -> UIColor {
        
        switch difficulty {
        case .beginner:
            return UIColor.systemGreen
        case .intermediate:
            return UIColor.systemOrange
        case .advanced:
            return UIColor.systemRed
        }
    }
    
    private func resolvedImage(named name: String, routineType: RoutineType) -> UIImage? {
        let baseName = (name as NSString).deletingPathExtension
        
        if let image = UIImage(named: name) ?? UIImage(named: baseName) {
            return image
        }
        
        if baseName.localizedCaseInsensitiveContains("walk") {
            return UIImage(named: "walking") ?? UIImage(named: "walk")
        }
        
        switch routineType {
        case .walking:
            return UIImage(named: "walking") ?? UIImage(named: "walk")
        case .yoga:
            return UIImage(named: "pranayama") ?? UIImage(named: "yoga")
        case .exercise:
            return UIImage(named: "relaxstretch") ?? UIImage(named: "routineExcercise")
        }
    }
    
}
