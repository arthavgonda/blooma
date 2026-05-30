//
//  DailyRoutineViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 02/02/26.
//

import UIKit

class DailyRoutineViewController: UIViewController {
    
    @IBOutlet weak var dailyRoutineCollectionView: UICollectionView!
    
    var routineType: RoutineType!
    var dataController: DataController!
    var selectedDate: Date!
    var currentSession: RoutineSession!
    
    private var routineItems: [RoutineItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)

        dailyRoutineCollectionView.backgroundColor = .clear

        navigationController?.navigationBar.tintColor = theme.accentPrimary
        navigationItem.largeTitleDisplayMode = .never
        
        register()
        
        dailyRoutineCollectionView.collectionViewLayout = generateLayout()
        dailyRoutineCollectionView.dataSource = self
        dailyRoutineCollectionView.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadRoutineItems()
    }
    
    private func register() {
        dailyRoutineCollectionView.register(UINib(nibName: "DailyRoutineCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "routine_control_cell")
        dailyRoutineCollectionView.register(UINib(nibName: "DailyRoutineHeaderCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "daily_routine_header")
        
    }
    
    private func loadRoutineItems() {
        dataController.loadTodayRoutineSnapshot { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.routineItems = self.dataController.getRoutineItems(for: self.routineType, date: self.selectedDate)
                self.dailyRoutineCollectionView.reloadData()
            }
        }
    }
    
    private func generateLayout() -> UICollectionViewLayout {
        
        // Card
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(210))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        // Header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(90))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func determineMode(progress: RoutineItemProgress) -> RoutineControlMode {
        
        switch progress.status {
            
        case .completed:
            return .completed
            
        case .skipped:
            return .skipped
            
        case .pending:
            return progress.elapsedSeconds > 0 ? .continueExercise : .start
            
        case .inProgress:
            return .pause
            
        case .paused, .partiallyCompleted:
            return .continueExercise
            
        }
    }
    
    private func handlePrimary(for indexPath: IndexPath) {
        
        var item = routineItems[indexPath.item]
        
        let progress = dataController.loadProgress(for: item, date: selectedDate)
        
        let newElapsed = progress.elapsedSeconds + 10
        
        let newStatus: RoutineItemStatus = newElapsed >= item.durationSeconds ? .completed : .inProgress
        
        dataController.saveProgress(for: item, elapsedSeconds: newElapsed, status: newStatus, date: selectedDate)
        
        item.status = newStatus
        routineItems[indexPath.item] = item
        
        dailyRoutineCollectionView.reloadItems(at: [indexPath])
    }
    
    private func handleSecondary(for indexPath: IndexPath) {
        
        var item = routineItems[indexPath.item]
        
        dataController.markItemSkipped(&item, date: selectedDate)
        
        routineItems[indexPath.item] = item
        
        dailyRoutineCollectionView.reloadItems(at: [indexPath])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "daily_to_item_detail", let indexPath = sender as? IndexPath, let destination = segue.destination as? RoutineItemDetailViewController else { return }
         let selectedItem = routineItems[indexPath.item]
         destination.routineItem = selectedItem
         destination.dataModel = dataController
         destination.selectedDate = selectedDate
         destination.title = selectedItem.title
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

extension DailyRoutineViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        routineItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routine_control_cell", for: indexPath) as! DailyRoutineCollectionViewCell
        
        let item = routineItems[indexPath.item]
        
        let progress = dataController.loadProgress(for: item, date: selectedDate)
        
        cell.configureCell(with: item, progress: progress, index: indexPath.item, dataController: dataController)
        
        return cell
    }   
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "daily_routine_header", for: indexPath) as! DailyRoutineHeaderCollectionReusableView
        
        let handled = routineItems.filter {
            let progress = dataController.loadProgress(for: $0, date: selectedDate)
            return progress.status == .completed || progress.status == .skipped
        }.count
        
        headerView.configure(title: "Today's Progress", completedItems: handled, totalItems: routineItems.count, routineType: routineType, theme: dataController.theme)
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 30)
        
        UIView.animate(withDuration: 0.5, delay: Double(indexPath.item) * 0.05, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.8, options: [], animations: {
            cell.alpha = 1
            cell.transform = .identity
        })
    }
}

extension DailyRoutineViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "daily_to_item_detail", sender: indexPath)
    }
}
