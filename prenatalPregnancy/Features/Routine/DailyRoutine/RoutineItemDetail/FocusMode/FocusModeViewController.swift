//
//  FocusModeViewControllerViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 18/02/26.
//

import UIKit

class FocusModeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var routineItem: RoutineItem!
    var dataModel: DataController!
    var selectedDate: Date!
    var videoName: String = "dummy"
    
    private var timer: Timer?
    
    private var elapsedSeconds = 0
    private var isPlaying = true
    
    private var currentHeartRate = 0
    private var peakHeartRate = 0
    private var currentSpo2 = 0
    private var peakSpo2 = 0
    private var currentCalories = 0
    private var didReceiveHealthCalories = false
    private var baselineHealthCalories = 0.0
    private var baselineSteps = 0
    private var latestHealthCalories = 0.0
    private var latestHealthSteps = 0
    private var continuedCaloriesOffset = 0
    private var continuedMovementOffset = 0
    private var continuedElapsedOffset = 0
    
    private var savedProgress: RoutineItemProgress!
    
    private var repCount = 0
    private let healthTracker = FocusWorkoutHealthTracker()
    
    private var didSkipWorkout = false
    private var didFinishWorkout = false
    
    private var totalDurationSeconds: Int {
        routineItem.durationSeconds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupCollectionView()
        loadSavedProgress()
        updateTimeLeftUI()
        dataModel.startHealthKitObservers()
        dataModel.refreshAndPublishTodayVitals()
        startFocusVitalsTracking()
        NotificationCenter.default.addObserver(self, selector: #selector(healthVitalsDidUpdate), name: .healthVitalsDidUpdate, object: nil)
        
        navigationItem.title = routineItem.title
        navigationItem.largeTitleDisplayMode = .never
        
        if savedProgress.status != .completed && savedProgress.status != .skipped {
            startTimer()
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = .landscape
        }
        
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        
        setNeedsUpdateOfSupportedInterfaceOrientations()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.collectionView.collectionViewLayout = self.generateLayout()
            self.collectionView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.collectionViewLayout = generateLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pauseWorkoutPlayback()
        timer?.invalidate()
        healthTracker.stop()
        NotificationCenter.default.removeObserver(self)
        
        tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = .portrait
        }
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        setNeedsUpdateOfSupportedInterfaceOrientations()
        
        if !didSkipWorkout && !didFinishWorkout {
            saveProgress()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }
    
    override var shouldAutorotate: Bool {
        true
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension FocusModeViewController {
    
    private func setupBackground() {
        
        let theme = dataModel.theme
        applyAnimatedBackground(theme: theme)
        
        title = routineItem.title
        
        navigationController?.navigationBar.tintColor = theme.accentPrimary
        
        collectionView.backgroundColor = .clear
    }
    
    private func loadSavedProgress() {
        
        savedProgress = dataModel.loadProgress(for: routineItem, date: selectedDate)
        
        elapsedSeconds = savedProgress.elapsedSeconds
        
        currentHeartRate = dataModel.latestHealthVitals?.avgHeartRate ?? 0
        peakHeartRate = dataModel.latestHealthVitals?.peakHeartRate ?? currentHeartRate
        currentSpo2 = Int(dataModel.latestHealthVitals?.avgSpO2?.rounded() ?? 0)
        peakSpo2 = Int(dataModel.latestHealthVitals?.peakSpO2?.rounded() ?? Double(currentSpo2))
        baselineSteps = dataModel.latestHealthVitals?.steps ?? 0
        baselineHealthCalories = dataModel.latestHealthVitals?.activeEnergyKcal ?? 0
        latestHealthSteps = baselineSteps
        latestHealthCalories = baselineHealthCalories
        continuedMovementOffset = max(0, savedProgress.repetitionsCompleted ?? 0)
        continuedCaloriesOffset = max(0, Int((savedProgress.caloriesBurned ?? 0).rounded()))
        continuedElapsedOffset = elapsedSeconds
        repCount = continuedMovementOffset
        currentCalories = max(continuedCaloriesOffset, savedProgress.caloriesBurned == nil ? estimatedCalories() : continuedCaloriesOffset)
    }
    
    private func updateTimeLeftUI() {
        
        let remaining = max(totalDurationSeconds - elapsedSeconds, 0)
        
        let minutes = remaining / 60
        let seconds = remaining % 60
        
        let formatted = String(format: "%02d:%02d", minutes, seconds)
        
        let text = "\(formatted) min left"

        guard let cell = collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? FocusStatsCollectionViewCell else { return }
        cell.updateTimeLeft(text)
    }

    @objc private func healthVitalsDidUpdate(_ notification: Notification) {
        guard let record = notification.userInfo?["record"] as? ActivityExecutionRecord else { return }

        dataModel.latestHealthVitals = record
        currentHeartRate = record.avgHeartRate ?? currentHeartRate
        peakHeartRate = max(peakHeartRate, record.peakHeartRate ?? currentHeartRate)
        currentSpo2 = Int(record.avgSpO2?.rounded() ?? Double(currentSpo2))
        peakSpo2 = max(peakSpo2, Int(record.peakSpO2?.rounded() ?? Double(currentSpo2)))

        if let steps = record.steps, routineItem.routineType == .walking {
            latestHealthSteps = steps
            
            if isPlaying {
                repCount = max(repCount, continuedMovementOffset + max(0, steps - baselineSteps))
            }
        }
        
        if let activeEnergy = record.activeEnergyKcal {
            latestHealthCalories = activeEnergy
            
            if isPlaying && !didReceiveHealthCalories {
                if activeEnergy > baselineHealthCalories {
                    currentCalories = max(currentCalories, continuedCaloriesOffset + Int((activeEnergy - baselineHealthCalories).rounded()))
                } else {
                    currentCalories = max(currentCalories, continuedCaloriesOffset + estimatedLiveSessionCalories())
                }
            }
        } else if isPlaying && !didReceiveHealthCalories {
            currentCalories = max(currentCalories, continuedCaloriesOffset + estimatedLiveSessionCalories())
        }

        updateStatsCellDirectly()
    }

    private func startFocusVitalsTracking() {
        healthTracker.onStatsChanged = { [weak self] stats in
            guard let self else { return }

            if let heartRate = stats.heartRate, heartRate > 0 {
                self.currentHeartRate = heartRate
            }

            if let peakHeartRate = stats.peakHeartRate, peakHeartRate > 0 {
                self.peakHeartRate = max(self.peakHeartRate, peakHeartRate)
            }

            if let spo2 = stats.spo2, spo2 > 0 {
                self.currentSpo2 = spo2
            }

            if let peakSpo2 = stats.peakSpo2, peakSpo2 > 0 {
                self.peakSpo2 = max(self.peakSpo2, peakSpo2)
            }

            if let steps = stats.steps, self.routineItem.routineType == .walking, self.isPlaying {
                self.repCount = max(self.repCount, self.continuedMovementOffset + steps)
            }

            if let calories = stats.calories, calories > 0, self.isPlaying {
                self.currentCalories = max(self.currentCalories, self.continuedCaloriesOffset + calories)
                self.didReceiveHealthCalories = true
            } else if self.isPlaying {
                self.currentCalories = max(self.currentCalories, self.continuedCaloriesOffset + self.estimatedLiveSessionCalories())
            }

            self.updateStatsCellDirectly()
        }

        healthTracker.start()
    }
    
    private func setupCollectionView() {
        
        collectionView.register(UINib(nibName: "FocusVideoPlayerCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "video_cell")
        
        collectionView.register(UINib(nibName: "FocusStatsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "stats_cell")
        
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        
        collectionView.collectionViewLayout = generateLayout()
    }
    
    private func presentSkipConfirmationAlert() {
        pauseWorkoutPlayback()
        
        let alert = UIAlertController(title: "Skip Workout?", message: "If you skip this workout, you won’t be able to complete it again for the next 24 hours.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Skip Workout", style: .destructive) { [weak self] _ in
            self?.skipTapped()
        }
        )
        
        present(alert, animated: true)
    }
    
    private func presentStopConfirmationAlert() {
        pauseWorkoutPlayback()
        
        let alert = UIAlertController(title: "Stop Workout?", message: "Your current progress will be saved and you can continue later.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Stop", style: .destructive) { [weak self] _ in
            self?.stopTapped()
        })
        
        present(alert, animated: true)
    }
    
    private func skipTapped() {
        
        pauseWorkoutPlayback()
        
        performSegue(withIdentifier: "show_feedback", sender: "skip")
    }
    
    private func stopTapped() {
        
        pauseWorkoutPlayback()
        saveProgress()
        exitFocusMode()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "show_feedback" {
            
            guard let navVC = segue.destination as? UINavigationController, let feedbackVC = navVC.topViewController as? RoutineFeedbackViewController
            else { return }
            
            feedbackVC.routineItem = routineItem
            feedbackVC.dataController = dataModel
            
            feedbackVC.onFeedbackCancelled = { [weak self] in
                guard let self = self else { return }
                
                if sender as? String == "completed" {
                    self.exitFocusMode()
                    return
                }
                
                if self.isPlaying && self.elapsedSeconds < self.totalDurationSeconds {
                    self.startTimer()
                    self.updateVideoProgressOnly()
                    self.updateTimeLeftUI()
                }
            }
            
            feedbackVC.onFeedbackSubmitted = { [weak self] in
                
                guard let self = self else { return }
                
                if sender as? String == "skip" {
                    
                    self.didSkipWorkout = true
                    
                    self.dataModel.markItemSkipped(&self.routineItem, date: self.selectedDate)
                }
                
                if sender as? String == "completed" {
                    self.didFinishWorkout = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.exitFocusMode()
                }
            }
            
            navVC.modalPresentationStyle = .pageSheet
            
            if let sheet = navVC.sheetPresentationController {
                
                sheet.detents = [
                    .custom { _ in 580 }
                ]
                
                sheet.preferredCornerRadius = 32
            }
        }
    }
    
}

extension FocusModeViewController {

    private func generateLayout() -> UICollectionViewLayout {

        return UICollectionViewCompositionalLayout { _, _ in
            
            let height = self.collectionView.bounds.height
            let width = self.collectionView.bounds.width
            
            let videoItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.6),
                    heightDimension: .absolute(height)
                )
            )
            
            let statsItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.4),
                    heightDimension: .absolute(height)
                )
            )
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(width),
                    heightDimension: .absolute(height)
                ),
                subitems: [videoItem, statsItem]
            )
            
            group.interItemSpacing = .fixed(0)
            
            let section = NSCollectionLayoutSection(group: group)
            
            section.contentInsets = .zero
            
            return section
        }
    }
}

extension FocusModeViewController {

    private func startTimer() {

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in

            self?.updateProgress()
        }
    }

    private func updateProgress() {

        guard isPlaying else { return }

        elapsedSeconds += 1

        if !didReceiveHealthCalories {
            currentCalories = max(currentCalories, continuedCaloriesOffset + estimatedLiveSessionCalories())
        }

        updateStatsCellDirectly()
        updateVideoProgressOnly()
        updateTimeLeftUI()

        if !didSkipWorkout {
            saveProgress()
        }

        if elapsedSeconds >= totalDurationSeconds {
            completeExercise()
        }
    }
}

extension FocusModeViewController {

    private func togglePlayPause() {

        isPlaying.toggle()

        if isPlaying {
            continuedMovementOffset = repCount
            continuedCaloriesOffset = currentCalories
            continuedElapsedOffset = elapsedSeconds
            baselineSteps = latestHealthSteps
            baselineHealthCalories = latestHealthCalories
            startTimer()
        } else {
            timer?.invalidate()
        }
        
        updateStatsCellDirectly()
        updateVideoProgressOnly()
    }

    private func saveProgress() {
        let status: RoutineItemStatus
        if elapsedSeconds >= totalDurationSeconds {
            status = .completed
        } else if elapsedSeconds > 0 && isPlaying {
            status = .inProgress
        } else if elapsedSeconds > 0 {
            status = .paused
        } else {
            status = .pending
        }

        dataModel.updateProgressVitals(
            for: routineItem,
            date: selectedDate,
            heartRate: currentHeartRate > 0 ? currentHeartRate : nil,
            peakHeartRate: peakHeartRate > 0 ? peakHeartRate : nil,
            spo2: currentSpo2 > 0 ? currentSpo2 : nil,
            peakSpo2: peakSpo2 > 0 ? peakSpo2 : nil,
            calories: currentCalories,
            steps: repCount,
            elapsedSeconds: elapsedSeconds,
            status: status
        )
    }

    private func completeExercise() {
        guard !didFinishWorkout else { return }

        timer?.invalidate()
        elapsedSeconds = totalDurationSeconds
        isPlaying = false
        didFinishWorkout = true

        dataModel.updateProgressVitals(
            for: routineItem,
            date: selectedDate,
            heartRate: currentHeartRate > 0 ? currentHeartRate : nil,
            peakHeartRate: peakHeartRate > 0 ? peakHeartRate : nil,
            spo2: currentSpo2 > 0 ? currentSpo2 : nil,
            peakSpo2: peakSpo2 > 0 ? peakSpo2 : nil,
            calories: currentCalories,
            steps: repCount,
            elapsedSeconds: elapsedSeconds,
            status: .completed
        )
        routineItem.status = .completed
        updateStatsCellDirectly()
        updateVideoProgressOnly()
        updateTimeLeftUI()
        
        if dataModel.shouldPromptForFeedback(for: routineItem.activityId, on: selectedDate) {
            pauseWorkoutPlayback()
            performSegue(withIdentifier: "show_feedback", sender: "completed")
        } else {
            exitFocusMode()
        }
    }
    
    private func exitFocusMode() {
        if let navigationController,
           navigationController.viewControllers.count > 1,
           navigationController.topViewController === self {
            navigationController.popViewController(animated: true)
            return
        }
        
        if let navigationController, navigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true)
            return
        }
        
        if presentingViewController != nil {
            dismiss(animated: true)
        }
    }
}

extension FocusModeViewController {

    private func updateStatsCellDirectly() {

        guard let cell = collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? FocusStatsCollectionViewCell else { return }

        cell.updateStats(heartRate: currentHeartRate, calories: currentCalories, spo2: currentSpo2, steps: repCount, routineType: routineItem.routineType)
    }

    private func updateVideoProgressOnly() {

        guard let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FocusVideoPlayerCollectionViewCell else { return }

        cell.updateProgress(elapsed: elapsedSeconds, total: totalDurationSeconds, isPlaying: isPlaying)
        cell.setPlayback(isPlaying)
    }
    
    private func pauseWorkoutPlayback() {
        isPlaying = false
        timer?.invalidate()
        
        guard let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FocusVideoPlayerCollectionViewCell else { return }
        
        cell.pauseVideo()
        cell.updateProgress(elapsed: elapsedSeconds, total: totalDurationSeconds, isPlaying: false)
    }
}

extension FocusModeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.item == 0 {

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "video_cell", for: indexPath) as! FocusVideoPlayerCollectionViewCell

            cell.configure(videoName: videoName, elapsed: elapsedSeconds, total: totalDurationSeconds, isPlaying: isPlaying, accent: routineItem.routineType.accentColor, theme: dataModel.theme, routineType: routineItem.routineType)

            cell.onPlayPauseTapped = { [weak self] in
                self?.togglePlayPause()
            }
            
            cell.onVideoLoopCompleted = { [weak self] in
                guard let self = self else { return }
                
                if self.routineItem.routineType != .walking {
                    self.repCount += 1
                    self.continuedMovementOffset = self.repCount
                    
                    self.updateStatsCellDirectly()
                }
            }

            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "stats_cell", for: indexPath) as! FocusStatsCollectionViewCell

        cell.configure(routineItem: routineItem, heartRate: currentHeartRate, calories: currentCalories, spo2: currentSpo2, steps: repCount, theme: dataModel.theme)
        cell.updateTimeLeft(timeLeftText())

        cell.onSkip = { [weak self] in
            self?.presentSkipConfirmationAlert()
        }
        
        cell.onStop = { [weak self] in
            self?.presentStopConfirmationAlert()
        }

        return cell
    }

    private func timeLeftText() -> String {
        let remaining = max(totalDurationSeconds - elapsedSeconds, 0)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d min left", minutes, seconds)
    }
    
    private func estimatedCalories() -> Int {
        estimatedCalories(durationSeconds: elapsedSeconds)
    }

    private func estimatedLiveSessionCalories() -> Int {
        estimatedCalories(durationSeconds: max(0, elapsedSeconds - continuedElapsedOffset))
    }

    private func estimatedCalories(durationSeconds: Int) -> Int {
        let met: Double
        
        switch routineItem.routineType {
        case .walking:
            met = 3.5
        case .yoga:
            met = 2.5
        case .exercise:
            met = 3.0
        }
        
        let estimatedWeightKg = 70.0
        let durationHours = Double(durationSeconds) / 3600.0
        return max(0, Int((met * estimatedWeightKg * durationHours).rounded()))
    }
}
