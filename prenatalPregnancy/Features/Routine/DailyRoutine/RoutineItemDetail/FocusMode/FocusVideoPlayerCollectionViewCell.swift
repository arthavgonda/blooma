//
//  FocusVideoPlayerCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 08/04/26.
//

import UIKit
import AVFoundation

class FocusVideoPlayerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var onPlayPauseTapped: (() -> Void)?
    var onVideoLoopCompleted: (() -> Void)?
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var shouldPlayVideo = false
    
    private var overlayHideWorkItem: DispatchWorkItem?
    
    var videoName: String = "dummy"
    private var currentRoutineType: RoutineType = .exercise
    private var videoRequestID = UUID()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
        setupGesture()
        
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = videoContainerView.bounds
        CATransaction.commit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cleanupPlayer()
    }
    
    deinit {
        cleanupPlayer()
    }
}

extension FocusVideoPlayerCollectionViewCell {
    
    func configure(videoName: String, elapsed: Int, total: Int, isPlaying: Bool, accent: UIColor, theme: AppTheme, routineType: RoutineType) {
        
        self.videoName = videoName
        self.currentRoutineType = routineType
        
        progressView.progressTintColor = accent
        
        updateProgress(elapsed: elapsed, total: total, isPlaying: isPlaying)
        
        if player == nil {
            setupVideo()
        }
        
        setPlayback(isPlaying)
    }
    
    func updateProgress(elapsed: Int, total: Int, isPlaying: Bool) {
        
        let progress = total > 0 ? Float(elapsed) / Float(total) : 0
        
        progressView.progress = progress
        
        timeLabel.text = "\(formatTime(elapsed)) / \(formatTime(total))"
        timeLabel.textColor = .white
        
        playPauseButton.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
    }
    
    func setPlayback(_ isPlaying: Bool) {
        shouldPlayVideo = isPlaying
        
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    func pauseVideo() {
        setPlayback(false)
    }
}

extension FocusVideoPlayerCollectionViewCell {
    
    private func setupUI() {
        
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        
        videoContainerView.layer.cornerRadius = 20
        videoContainerView.clipsToBounds = true
        
        overlayView.layer.cornerRadius = 20
        overlayView.clipsToBounds = true
        
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        overlayView.alpha = 1
    }
    
    private func setupGesture() {
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleVideoTap))
        
        containerView.addGestureRecognizer(tap)
    }
    
    private func setupVideo() {
        let requestID = UUID()
        videoRequestID = requestID

        CloudinaryVideoService.shared.loadVideo(named: videoName, routineType: currentRoutineType) { [weak self] cachedURL in
            guard let self else { return }
            guard self.videoRequestID == requestID else {
                print("ℹ️ [FocusVideo] Ignoring stale video callback for \(self.videoName)")
                return
            }

            let playbackURL = cachedURL ?? self.resolvedFallbackVideoURL()
            guard let playbackURL else {
                print("⛔ [FocusVideo] No playable video URL for \(self.videoName)")
                return
            }

            if cachedURL == nil {
                print("⚠️ [FocusVideo] Falling back to bundled dummy.mp4 for \(self.videoName)")
            } else {
                print("✅ [FocusVideo] Playing cached Cloudinary video: \(self.videoName)")
            }

            self.setupPlayer(with: playbackURL)
        }
    }

    private func setupPlayer(with url: URL) {
        videoContainerView.layoutIfNeeded()
        
        player = AVPlayer(url: url)
        
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        
        playerLayer = layer
        
        videoContainerView.layer.insertSublayer(layer, at: 0)
        
        DispatchQueue.main.async {
            layer.frame = self.videoContainerView.bounds
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(loopVideo), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        scheduleOverlayHide()

        if shouldPlayVideo {
            player?.play()
        }
    }
}

extension FocusVideoPlayerCollectionViewCell {
    
    @objc private func loopVideo() {
        guard shouldPlayVideo, window != nil else { return }
        
        player?.seek(to: .zero)
        player?.play()
        
        onVideoLoopCompleted?()
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        
        guard let player else { return }
        
        let isCurrentlyPlaying = player.timeControlStatus == .playing
        
        if isCurrentlyPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        shouldPlayVideo = !isCurrentlyPlaying
        
        onPlayPauseTapped?()
        
        playPauseButton.setImage(UIImage(systemName: isCurrentlyPlaying ? "play.fill" : "pause.fill"), for: .normal)
        
        playPauseButton.tintColor = .white
        
        showOverlay()
    }
    
}

extension FocusVideoPlayerCollectionViewCell {
    
    @objc private func handleVideoTap() {
        
        if overlayView.alpha == 0 {
            showOverlay()
        } else {
            hideOverlay()
        }
    }
    
    private func showOverlay() {
        
        UIView.animate(withDuration: 0.25) {
            self.overlayView.alpha = 1
        }
        
        scheduleOverlayHide()
    }
    
    private func hideOverlay() {
        
        UIView.animate(withDuration: 0.25) {
            self.overlayView.alpha = 0
        }
    }
    
    private func scheduleOverlayHide() {
        
        overlayHideWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.hideOverlay()
        }
        
        overlayHideWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
}

extension FocusVideoPlayerCollectionViewCell {
    
    private func cleanupPlayer() {
        shouldPlayVideo = false
        videoRequestID = UUID()
        overlayHideWorkItem?.cancel()
        overlayHideWorkItem = nil
        
        NotificationCenter.default.removeObserver(self)
        
        player?.pause()
        player = nil
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    private func resolvedFallbackVideoURL() -> URL? {
        Bundle.main.bloomaResourceURL(named: "dummy", fileExtension: "mp4")
    }
}
