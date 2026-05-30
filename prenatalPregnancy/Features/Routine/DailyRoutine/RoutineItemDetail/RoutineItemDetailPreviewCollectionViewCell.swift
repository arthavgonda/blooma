//
//  RoutineControlCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 18/02/26.
//

import UIKit
import AVFoundation

class RoutineItemDetailPreviewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var skippedButton: UIButton!
    
    var onStartTapped: (() -> Void)?
    var onSkipTapped: (() -> Void)?
    
    var theme: AppTheme!
    private var accentColor: UIColor = .systemGreen

    /// Stored so CloudinaryImageCache can pick the correct folder.
    private var currentRoutineType: RoutineType = .exercise

    var videoName: String = "dummy"
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var shouldPlayVideo = true
    private var isObservingPlayerItemStatus = false
    private var videoRequestID = UUID()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cleanupPlayer()
        
        previewImageView.alpha = 1
        videoView.alpha = 0
        
        startButton.isHidden = false
        skipButton.isHidden = false
        skippedButton.isHidden = true
    }
    
    deinit {
        cleanupPlayer()
    }
    
    func pauseVideo() {
        shouldPlayVideo = false
        player?.pause()
    }
    
    private func cleanupPlayer() {
        shouldPlayVideo = false
        videoRequestID = UUID()
        NotificationCenter.default.removeObserver(self)
        
        if isObservingPlayerItemStatus, let item = playerItem {
            item.removeObserver(self, forKeyPath: "status")
            isObservingPlayerItemStatus = false
        }
        
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        
        player = nil
        playerLayer = nil
        playerItem = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = videoView.bounds
        CATransaction.commit()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard keyPath == "status", let item = object as? AVPlayerItem else { return }
        
        if item.status == .readyToPlay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                
                guard self.shouldPlayVideo, self.window != nil else { return }
                
                UIView.animate(withDuration: 0.4) {
                    self.previewImageView.alpha = 0
                    self.videoView.alpha = 1
                }
                
                self.player?.play()
            }
        }
    }
    
    private func setupUI() {
        previewContainerView.layer.cornerRadius = 22
        previewContainerView.clipsToBounds = true
        previewContainerView.backgroundColor = theme.glassMedium
        
        contentContainerView.clipsToBounds = true
        contentContainerView.layer.cornerRadius = 18
        
        previewImageView.layer.cornerRadius = 18
        previewImageView.clipsToBounds = true
        
        videoView.layer.cornerRadius = 18
        videoView.clipsToBounds = true
        
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(.black, for: .normal)
        
        progressView.trackTintColor = theme.glassMedium
        timerLabel.textColor = theme.primaryText
        
        applyGlass(to: startButton, filled: true)
        applyGlass(to: skipButton, filled: false)
        applyDisabledGlass(to: skippedButton)
    }
    
    func configure(image: String, videoName: String, elapsed: Int, total: Int, theme: AppTheme, accent: UIColor, routineType: RoutineType = .exercise, mode: RoutineControlMode) {
        cleanupPlayer()

        self.theme = theme
        self.accentColor = accent
        self.videoName = videoName
        self.currentRoutineType = routineType

        setupUI()

        // Show local asset immediately as placeholder — no blank frame.
        let localFallback = resolvedImage(named: image)
        previewImageView.image = localFallback
        previewImageView.alpha = 1
        videoView.alpha = 0

        // Async upgrade to Cloudinary image.
        CloudinaryImageCache.shared.loadImage(
            named: image,
            routineType: routineType,
            fallback: localFallback
        ) { [weak self] fetchedImage in
            guard let self else { return }
            if let fetchedImage {
                self.previewImageView.image = fetchedImage
            }
        }

        updateProgress(elapsed: elapsed, total: total)
        configureButtons(mode: mode)

        shouldPlayVideo = !(mode == .skipped || mode == .completed)

        if shouldPlayVideo {
            setupVideo()
        }
    }
    
    private func setupVideo() {
        let requestID = UUID()
        videoRequestID = requestID

        CloudinaryVideoService.shared.loadVideo(named: videoName, routineType: currentRoutineType) { [weak self] cachedURL in
            guard let self else { return }
            guard self.videoRequestID == requestID, self.shouldPlayVideo else {
                print("ℹ️ [RoutinePreviewVideo] Ignoring stale video callback for \(self.videoName)")
                return
            }

            let playbackURL = cachedURL ?? self.resolvedFallbackVideoURL()
            guard let playbackURL else {
                print("⛔ [RoutinePreviewVideo] No playable video URL for \(self.videoName)")
                return
            }

            if cachedURL == nil {
                print("⚠️ [RoutinePreviewVideo] Falling back to bundled dummy.mp4 for \(self.videoName)")
            } else {
                print("✅ [RoutinePreviewVideo] Playing cached Cloudinary video: \(self.videoName)")
            }

            self.setupPlayer(with: playbackURL)
        }
    }

    private func setupPlayer(with url: URL) {
        layoutIfNeeded()
        videoView.layoutIfNeeded()
        
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = videoView.bounds
        
        videoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        videoView.layer.addSublayer(layer)
        playerLayer = layer
        
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        isObservingPlayerItemStatus = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(loopVideo), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @objc private func loopVideo() {
        guard shouldPlayVideo, window != nil else { return }
        
        player?.seek(to: .zero)
        player?.play()
    }
    
    private func updateProgress(elapsed: Int, total: Int) {
        let progress = total > 0 ? Float(elapsed) / Float(total) : 0
        progressView.progressTintColor = accentColor
        progressView.progress = progress
        timerLabel.text = "\(formatTime(elapsed)) / \(formatTime(total))"
    }
    
    private func configureButtons(mode: RoutineControlMode) {
        startButton.isHidden = false
        skipButton.isHidden = false
        skippedButton.isHidden = true
        
        switch mode {
        case .start:
            startButton.setTitle("Start", for: .normal)
        case .continueExercise:
            startButton.setTitle("Continue", for: .normal)
        case .pause:
            startButton.setTitle("Pause", for: .normal)
        case .play:
            startButton.setTitle("Play", for: .normal)
        case .completed:
            showSkipped(title: "Completed")
        case .skipped:
            showSkipped(title: "Skipped")
        }
    }
    
    private func showSkipped(title: String) {
        startButton.isHidden = true
        skipButton.isHidden = true
        
        skippedButton.isHidden = false
        skippedButton.setTitle(title, for: .normal)
    }
    
    private func applyGlass(to button: UIButton, filled: Bool) {
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        
        if filled {
            button.backgroundColor = accentColor
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            button.setTitleColor(.black, for: .normal)
            
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        }
    }
    
    private func applyDisabledGlass(to button: UIButton) {
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        
        button.backgroundColor = theme.glassThin.withAlphaComponent(0.6)
        button.setTitleColor(theme.secondaryText, for: .normal)
        
        button.layer.borderWidth = 1
        button.layer.borderColor = theme.primaryText.withAlphaComponent(0.1).cgColor
    }
    
    @IBAction func startTapped(_ sender: UIButton) {
        onStartTapped?()
    }
    
    @IBAction func skipTapped(_ sender: UIButton) {
        onSkipTapped?()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    private func resolvedImage(named name: String) -> UIImage? {
        let baseName = (name as NSString).deletingPathExtension
        
        if baseName.localizedCaseInsensitiveContains("walk") {
            return UIImage(named: name)
                ?? UIImage(named: baseName)
                ?? UIImage(named: "walking")
                ?? UIImage(named: "walk")
        }
        
        return UIImage(named: name)
            ?? UIImage(named: baseName)
            ?? UIImage(named: "walking")
            ?? UIImage(named: "dummy")
    }
    
    private func resolvedFallbackVideoURL() -> URL? {
        Bundle.main.bloomaResourceURL(named: "dummy", fileExtension: "mp4")
    }
}
