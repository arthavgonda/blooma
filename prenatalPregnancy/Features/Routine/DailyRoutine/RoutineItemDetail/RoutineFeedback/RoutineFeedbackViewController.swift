//
//  RoutineFeedbackViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 05/02/26.
//

import UIKit

class RoutineFeedbackViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    var routineItem: RoutineItem!
    var dataController: DataController!
    
    private var selectedDifficultyIndex: Int?
    private var selectedFatigueIndex: Int?
    private var notesText: String?
    
    var onFeedbackSubmitted: (() -> Void)?
    var onFeedbackCancelled: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView.transform = CGAffineTransform(translationX: 0, y: 18)
        collectionView.alpha = 0.96
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.4, options: [.allowUserInteraction]) {
            self.collectionView.transform = .identity
            self.collectionView.alpha = 1
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom

        collectionView.contentInset.bottom = bottomInset + 16
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset

        scrollToNotes()
    }

    @objc private func keyboardWillHide(notification: Notification) {
        collectionView.contentInset.bottom = 0
        collectionView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    private func scrollToNotes() {
        let indexPath = IndexPath(item: 0, section: Section.notes.rawValue)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
    
    private func setupUI() {
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)

        title = "Feedback"
        navigationItem.leftBarButtonItem = circularIconBarButton(systemName: "xmark", action: #selector(cancelIconTapped))
        navigationItem.rightBarButtonItem = circularIconBarButton(systemName: "checkmark", action: #selector(doneIconTapped))
        doneBarButton?.isEnabled = false
        cancelBarButton?.isEnabled = false
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        
        collectionView.backgroundColor = .clear
        
        // Cells
        collectionView.register(UINib(nibName: "HeaderCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "HeaderCollectionViewCell")
        collectionView.register(UINib(nibName: "OptionsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "OptionsCollectionViewCell")
        collectionView.register(UINib(nibName: "NotesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "NotesCollectionViewCell")
        
        // Header reusable
        collectionView.register(UINib(nibName: "SectionTitleReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionTitleReusableView")
        
        collectionView.collectionViewLayout = generateLayout()
    }
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        submitFeedback()
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        cancelFeedback()
    }

    @objc private func doneIconTapped() {
        submitFeedback()
    }

    @objc private func cancelIconTapped() {
        cancelFeedback()
    }
    
    private func submitFeedback() {
        guard let diff = selectedDifficultyIndex, let fat = selectedFatigueIndex else {
            showAlert(title: "Incomplete", message: "Please select all options")
            return
        }
        
        let difficulty = DifficultyLevel.allCases[diff]
        let fatigue = FatigueLevel.allCases[fat]
        
        dataController.saveUserFeedback(activityId: routineItem.activityId, difficulty: difficulty, fatigue: fatigue, note: notesText)
        
        onFeedbackSubmitted?()
        dismiss(animated: true)
    }
    
    private func cancelFeedback() {
        onFeedbackCancelled?()
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

extension RoutineFeedbackViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let theme = dataController.theme

        switch Section(rawValue: indexPath.section)! {

        case .header:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCollectionViewCell", for: indexPath) as! HeaderCollectionViewCell
            cell.configure(title: "Workout Feedback", subtitle: "Tell us how this activity felt", theme: theme)
            return cell

        case .difficulty:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionsCollectionViewCell", for: indexPath) as! OptionsCollectionViewCell

            cell.configure(options: ["Beginner", "Intermediate", "Advanced"], selected: selectedDifficultyIndex, theme: theme)

            cell.onSelectionChanged = { [weak self] index in
                self?.selectedDifficultyIndex = index
            }

            return cell

        case .fatigue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionsCollectionViewCell", for: indexPath) as! OptionsCollectionViewCell

            cell.configure(options: ["Low", "Moderate", "High"], selected: selectedFatigueIndex, theme: theme)

            cell.onSelectionChanged = { [weak self] index in
                self?.selectedFatigueIndex = index
            }

            return cell

        case .notes:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotesCollectionViewCell", for: indexPath) as! NotesCollectionViewCell

            cell.configure(theme: theme)

            cell.textView.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionTitleReusableView", for: indexPath) as! SectionTitleReusableView

        let theme = dataController.theme

        switch Section(rawValue: indexPath.section)! {
        case .difficulty:
            header.configure(title: "Difficulty", theme: theme)
        case .fatigue:
            header.configure(title: "Fatigue Level", theme: theme)
        case .notes:
            header.configure(title: "Additional Notes (Optional)", theme: theme)
        default:
            break
        }

        return header
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

extension RoutineFeedbackViewController {

    private func generateLayout() -> UICollectionViewLayout {

        return UICollectionViewCompositionalLayout { sectionIndex, _ in

            let section = Section(rawValue: sectionIndex)!

            switch section {

            case .header:
                return self.createSection(height: 70, hasHeader: false)

            case .difficulty:
                return self.createSection(height: 80, hasHeader: true)

            case .fatigue:
                return self.createSection(height: 80, hasHeader: true)

            case .notes:
                return self.createSection(height: 200, hasHeader: true)
            }
        }
    }
    
    private func createSection(height: CGFloat, hasHeader: Bool) -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(height))

        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        if hasHeader {
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))

            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

            section.boundarySupplementaryItems = [header]
        }

        return section
    }
}

extension RoutineFeedbackViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        notesText = textView.text
    }
}
