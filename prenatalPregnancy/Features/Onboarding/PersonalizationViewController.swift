//
//  PersonalizationViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 01/04/26.
//

import UIKit

class PersonalizationViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var theme: AppTheme!
    var dataController: DataController!
    
    enum Section: Int, CaseIterable {
        case hero
        case progress
        case steps
        case continueCTA
    }
    
    private var timer: Timer?
    private var currentStepIndex = 0
    private var didFinishProcessing = false
    private var isSavingAndNavigating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        theme = dataController.theme
        navigationItem.hidesBackButton = true
        
        configureScreen()
        registerCells()
        collectionView.collectionViewLayout = makeLayout()
        collectionView.reloadData()
        startFilteringAnimation()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func configureScreen() {
        view.backgroundColor = UIColor(hex: "#FBE8EE")
        navigationController?.navigationBar.isHidden = true
        
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.allowsSelection = false
        collectionView.contentInsetAdjustmentBehavior = .always
    }
    
    private func registerCells() {
        collectionView.register(UINib(nibName: PersonalizationFlowContent.ReuseID.hero, bundle: nil), forCellWithReuseIdentifier: PersonalizationFlowContent.ReuseID.hero)
        collectionView.register(UINib(nibName: PersonalizationFlowContent.ReuseID.progress, bundle: nil), forCellWithReuseIdentifier: PersonalizationFlowContent.ReuseID.progress)
        collectionView.register(UINib(nibName: PersonalizationFlowContent.ReuseID.step, bundle: nil), forCellWithReuseIdentifier: PersonalizationFlowContent.ReuseID.step)
        collectionView.register(UINib(nibName: PersonalizationFlowContent.ReuseID.continueCTA, bundle: nil), forCellWithReuseIdentifier: PersonalizationFlowContent.ReuseID.continueCTA)
    }
    
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            return self?.layoutSection(for: section)
        }
    }
    
    private func layoutSection(for section: Section) -> NSCollectionLayoutSection {
        let height: NSCollectionLayoutDimension
        let insets: NSDirectionalEdgeInsets
        
        switch section {
        case .hero:
            height = .absolute(214)
            insets = .init(top: 18, leading: 20, bottom: 10, trailing: 20)
        case .progress:
            height = .absolute(96)
            insets = .init(top: 0, leading: 20, bottom: 12, trailing: 20)
        case .steps:
            height = .absolute(92)
            insets = .init(top: 0, leading: 20, bottom: 8, trailing: 20)
        case .continueCTA:
            height = .absolute(106)
            insets = .init(top: 8, leading: 20, bottom: 22, trailing: 20)
        }
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: height)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: height)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let layoutSection = NSCollectionLayoutSection(group: group)
        layoutSection.contentInsets = insets
        layoutSection.interGroupSpacing = section == .steps ? 4 : 0
        return layoutSection
    }
    
    private func startFilteringAnimation() {
        updateProgressExperience(activeIndex: 0, animated: false)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] timer in
            guard let self else { return }
            
            let steps = RoutineProcessingStep.allCases
            if self.currentStepIndex >= steps.count {
                timer.invalidate()
                self.revealContinueButton()
                return
            }
            
            self.updateProgressExperience(activeIndex: self.currentStepIndex, animated: true)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.currentStepIndex += 1
        }
    }
    
    private func updateProgressExperience(activeIndex: Int, animated: Bool) {
        let total = RoutineProcessingStep.allCases.count
        let clampedIndex = min(max(activeIndex, 0), total - 1)
        let progressIndex = didFinishProcessing ? total : clampedIndex + 1
        let progress = CGFloat(progressIndex) / CGFloat(total)
        
        if let heroCell = collectionView.cellForItem(at: IndexPath(item: 0, section: Section.hero.rawValue)) as? PersonalizationHeroCollectionViewCell {
            heroCell.configure(theme: theme, isComplete: didFinishProcessing)
        }
        
        if let progressCell = collectionView.cellForItem(at: IndexPath(item: 0, section: Section.progress.rawValue)) as? PersonalizationProgressCollectionViewCell {
            progressCell.configure(stepIndex: progressIndex, totalSteps: total, progress: progress, theme: theme, animated: animated)
        }
        
        let visibleStepPaths = collectionView.indexPathsForVisibleItems.filter { $0.section == Section.steps.rawValue }
        visibleStepPaths.forEach { indexPath in
            guard let cell = collectionView.cellForItem(at: indexPath) as? PersonalizationStepsCollectionViewCell else { return }
            configureStepCell(cell, at: indexPath, animated: animated)
        }
        
        let activePath = IndexPath(item: clampedIndex, section: Section.steps.rawValue)
        collectionView.scrollToItem(at: activePath, at: .centeredVertically, animated: animated)
    }
    
    private func revealContinueButton() {
        guard !didFinishProcessing else { return }
        
        didFinishProcessing = true
        let total = RoutineProcessingStep.allCases.count
        collectionView.isScrollEnabled = true
        
        collectionView.reloadSections(IndexSet(integersIn: Section.hero.rawValue...Section.continueCTA.rawValue))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let progressPath = IndexPath(item: 0, section: Section.progress.rawValue)
            if let progressCell = self.collectionView.cellForItem(at: progressPath) as? PersonalizationProgressCollectionViewCell {
                progressCell.configure(stepIndex: total, totalSteps: total, progress: 1, theme: self.theme, animated: true)
            }
            
            let continuePath = IndexPath(item: 0, section: Section.continueCTA.rawValue)
            self.collectionView.scrollToItem(at: continuePath, at: .bottom, animated: true)
        }
    }
    
    private func configureStepCell(_ cell: PersonalizationStepsCollectionViewCell, at indexPath: IndexPath, animated: Bool) {
        let step = RoutineProcessingStep.allCases[indexPath.item]
        let state: PersonalizationStepsCollectionViewCell.State
        
        if didFinishProcessing || indexPath.item < currentStepIndex {
            state = .complete
        } else if indexPath.item == min(currentStepIndex, RoutineProcessingStep.allCases.count - 1) {
            state = .active
        } else {
            state = .pending
        }
        
        cell.configure(step: step, stepNumber: indexPath.item + 1, state: state, theme: theme, animated: animated)
    }
    
    private func finishAndNavigate() {
        guard didFinishProcessing, !isSavingAndNavigating else { return }
        isSavingAndNavigating = true
        
        dataController.saveProfileToFirestore()
        dataController.markOnboardingCompleted()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.dataController.loadTodayRoutineSnapshot {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabBarVC = storyboard.instantiateViewController(identifier: "MainTabBarController") as! MainTabBarController
                    
                    tabBarVC.dataController = self.dataController
                    
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = scene.windows.first else { return }
                    
                    UIView.transition(with: window,
                                      duration: 0.4,
                                      options: .transitionCrossDissolve) {
                        window.rootViewController = tabBarVC
                    }
                }
            }
        }
    }
}

extension PersonalizationViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .hero, .progress:
            return 1
        case .steps:
            return RoutineProcessingStep.allCases.count
        case .continueCTA:
            return didFinishProcessing ? 1 : 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UICollectionViewCell() }
        
        switch section {
        case .hero:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalizationFlowContent.ReuseID.hero, for: indexPath) as! PersonalizationHeroCollectionViewCell
            cell.configure(theme: theme, isComplete: didFinishProcessing)
            return cell
            
        case .progress:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalizationFlowContent.ReuseID.progress, for: indexPath) as! PersonalizationProgressCollectionViewCell
            let total = RoutineProcessingStep.allCases.count
            let stepIndex = didFinishProcessing ? total : min(currentStepIndex + 1, total)
            cell.configure(stepIndex: stepIndex, totalSteps: total, progress: CGFloat(stepIndex) / CGFloat(total), theme: theme, animated: false)
            return cell
            
        case .steps:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalizationFlowContent.ReuseID.step, for: indexPath) as! PersonalizationStepsCollectionViewCell
            configureStepCell(cell, at: indexPath, animated: false)
            return cell
            
        case .continueCTA:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalizationFlowContent.ReuseID.continueCTA, for: indexPath) as! PersonalizationContinueCollectionViewCell
            cell.configure(theme: theme)
            cell.onContinueTapped = { [weak self] in
                self?.finishAndNavigate()
            }
            return cell
        }
    }
}
