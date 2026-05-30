//
//  RoutineItemDetailViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 03/02/26.
//

import UIKit

class RoutineItemDetailViewController: UIViewController {
    
    @IBOutlet weak var contentCollectionView: UICollectionView!
    
    var routineItem: RoutineItem!
    var dataModel: DataController!
    var selectedDate: Date!
    var videoName: String = "dummy"
    
    private var savedProgress: RoutineItemProgress!
    
    private var totalDurationSeconds: Int {
        routineItem.durationSeconds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme = dataModel.theme
        applyAnimatedBackground(theme: theme)

        contentCollectionView.backgroundColor = .clear

        navigationController?.navigationBar.tintColor = theme.accentPrimary
        navigationItem.largeTitleDisplayMode = .never
        
        registerCells()
        savedProgress = dataModel.loadProgress(for: routineItem, date: selectedDate)
        setupCollectionView()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        savedProgress = dataModel.loadProgress(for: routineItem, date: selectedDate)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {

            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

            self.contentCollectionView.collectionViewLayout.invalidateLayout()
            self.contentCollectionView.setCollectionViewLayout(self.generateLayout(), animated: false)

            self.contentCollectionView.reloadData()
            self.contentCollectionView.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pausePreviewVideo()
    }
    
    private func registerCells() {
        
        contentCollectionView.register(UINib(nibName: "RoutineItemDetailPreviewCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "preview_cell")
        
        contentCollectionView.register(UINib(nibName: "RoutineItemDetailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "routine_item_detail")
        
        contentCollectionView.register(UINib(nibName: "RoutineItemDetailHeadingCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: "header", withReuseIdentifier: "heading_view")
    }
    
    private func setupCollectionView() {
        
        contentCollectionView.dataSource = self
        contentCollectionView.collectionViewLayout = generateLayout()
    }
    
    
    private func generateLayout() -> UICollectionViewLayout {

        return UICollectionViewCompositionalLayout { sectionIndex, _ in

            if sectionIndex == 0 {
                // control cell
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(320))
                let item = NSCollectionLayoutItem(layoutSize: groupSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                return section
            }

            let sectionType = DetailSection(rawValue: sectionIndex - 1)!

            let height: NSCollectionLayoutDimension

            switch sectionType {
            case .description:
                height = .estimated(80)
            case .benefits, .safety, .instructions:
                height = .estimated(60)
            }

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: height)

            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 0
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(42))

            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "header", alignment: .top)
            header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0)

            section.boundarySupplementaryItems = [header]

            return section
        }
    }
    
    private func getControlMode() -> RoutineControlMode {

        let progress = dataModel.loadProgress(for: routineItem, date: selectedDate)

        switch progress.status {

        case .completed:
            return .completed

        case .skipped:
            return .skipped

        case .pending:
            if progress.elapsedSeconds == 0 {
                return .start
            } else {
                return .continueExercise
            }
            
        case .inProgress:
            return .pause
            
        case .paused, .partiallyCompleted:
            return .continueExercise
            
        }
    }
    
    private func startOrContinueTapped() {
        pausePreviewVideo()
        
        performSegue(withIdentifier: "routine_to_focusMode", sender: self)
    }
    
    private func skipTapped() {
        pausePreviewVideo()
        
        performSegue(withIdentifier: "routine_to_feedback", sender: "skip")
    }
    
    private func presentSkipConfirmationAlert() {

        let alert = UIAlertController(title: "Skip Workout?", message: "If you skip this workout, you won’t be able to complete it again for the next 24 hours.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let skipAction = UIAlertAction(title: "Skip Workout", style: .destructive) { [weak self] _ in
            self?.skipTapped()
        }
        alert.addAction(cancelAction)
        alert.addAction(skipAction)
        pausePreviewVideo()
        present(alert, animated: true)
    }
    
    private func pausePreviewVideo() {
        let indexPath = IndexPath(item: 0, section: 0)
        
        guard let cell = contentCollectionView.cellForItem(at: indexPath) as? RoutineItemDetailPreviewCollectionViewCell else { return }
        
        cell.pauseVideo()
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "routine_to_focusMode" {
            
            guard let focusVC = segue.destination as? FocusModeViewController else { return }
            
            focusVC.routineItem = routineItem
            focusVC.dataModel = dataModel
            focusVC.selectedDate = selectedDate
            focusVC.videoName = routineItem.video
            
            focusVC.modalPresentationStyle = .pageSheet
            
            if let sheet = focusVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
        }
        
        if segue.identifier == "routine_to_feedback" {
            
            guard let navVC = segue.destination as? UINavigationController,
                  let feedbackVC = navVC.topViewController as? RoutineFeedbackViewController else { return }

            feedbackVC.routineItem = routineItem
            feedbackVC.dataController = dataModel

            feedbackVC.onFeedbackSubmitted = { [weak self] in
                guard let self = self else { return }

                if sender as? String == "skip" {
                    self.dataModel.markItemSkipped(&self.routineItem, date: self.selectedDate)
                }

                self.savedProgress = self.dataModel.loadProgress(for: self.routineItem, date: self.selectedDate)
                self.contentCollectionView.reloadData()
            }
            
            navVC.modalPresentationStyle = .pageSheet

            if let sheet = navVC.sheetPresentationController {
                sheet.detents = [
                    .custom { _ in
                        return 580
                    }
                ]
                sheet.preferredCornerRadius = 32
            }
        }
        
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

extension RoutineItemDetailViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return DetailSection.allCases.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section > 0 else { return 1 }
        let sectionType = DetailSection(rawValue: section - 1)!
        
        switch sectionType {
        case .description:
            return 1
        case .benefits:
            return max(routineItem.benefits.count, 1)
        case .safety:
            return max(routineItem.safetyTips.count, 1)
        case .instructions:
            return max(routineItem.instructions.count, 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "preview_cell", for: indexPath) as! RoutineItemDetailPreviewCollectionViewCell
            
            let theme = dataModel.theme
            let accent = routineItem.routineType.accentColor
            
            let progress = dataModel.loadProgress(for: routineItem, date: selectedDate)
            
            let mode = getControlMode()
            
            videoName = routineItem.video
            
            cell.configure(image: routineItem.image, videoName: videoName, elapsed: progress.elapsedSeconds, total: totalDurationSeconds, theme: theme, accent: accent, routineType: routineItem.routineType, mode: mode)
            
            cell.onStartTapped = { [weak self] in
                self?.startOrContinueTapped()
            }
            
            cell.onSkipTapped = { [weak self] in
                self?.presentSkipConfirmationAlert()
            }
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routine_item_detail", for: indexPath) as! RoutineItemDetailCollectionViewCell
        
        let sectionType = DetailSection(rawValue: indexPath.section - 1)!
        let itemCount = collectionView.numberOfItems(inSection: indexPath.section)
        let isFirst = indexPath.item == 0
        let isLast = indexPath.item == itemCount - 1
        
        switch sectionType {

        case .description:
            cell.configureDescription(routineItem.description, theme: dataModel.theme)

        case .benefits:
            let text = routineItem.benefits[safe: indexPath.item] ?? ""
            cell.configurePoint(text, theme: dataModel.theme, isFirst: isFirst, isLast: isLast)

        case .safety:
            let text = routineItem.safetyTips[safe: indexPath.item] ?? ""
            cell.configurePoint(text, theme: dataModel.theme, isFirst: isFirst, isLast: isLast)

        case .instructions:
            let text = routineItem.instructions[safe: indexPath.item] ?? ""
            cell.configurePoint(text, theme: dataModel.theme, isFirst: isFirst, isLast: isLast)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var headerView: RoutineItemDetailHeadingCollectionReusableView!
        if kind == "header" {
            headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "heading_view", for: indexPath) as? RoutineItemDetailHeadingCollectionReusableView
            let sectionType = DetailSection(rawValue: indexPath.section - 1)!
            switch sectionType {
            case .description:
                headerView.configureCell(withTitle: "Description", theme: dataModel.theme)
                
            case .benefits:
                headerView.configureCell(withTitle: "Benefits", theme: dataModel.theme)
                
            case .safety:
                headerView.configureCell(withTitle: "Safety Tips", theme: dataModel.theme)
            case .instructions:
                headerView.configureCell(withTitle: "Instructions", theme: dataModel.theme)
            }
        }
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 30)
        
        UIView.animate(withDuration: 0.5, delay: Double(indexPath.section) * 0.08, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.8, options: [], animations: {
                cell.alpha = 1
                cell.transform = .identity
            }
        )
    }
    
}
