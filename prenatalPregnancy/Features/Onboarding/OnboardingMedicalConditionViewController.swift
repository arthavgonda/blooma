//
//  OnboardingMedicalConditionViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 09/02/26.
//

import UIKit

class OnboardingMedicalConditionViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var conditionsLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var dataController: DataController!
    var appName: String = "Blooma"
    
    var pageIndex: Int = 3
    var totalPages: Int = 5
    
    private let primaryConditions = MedicalCondition.allCases
    
    private var selectedPrimary = Set<MedicalCondition>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        registerCell()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = generateLayout()
        
        updateNextButtonState()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreSavedConditions()
    }

    private func restoreSavedConditions() {
        dataController.loadProfileFromFirestore { [weak self] profile in
            guard let self, let profile else { return }
            DispatchQueue.main.async {
                self.selectedPrimary = Set(profile.medicalConditions)
                self.collectionView.reloadData()
                self.updateNextButtonState()
            }
        }
    }
    
    private func configureUI() {
        
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        
        titleLabel.text = "Your health matters"
        titleLabel.textColor = theme.primaryText
        
        subtitleLabel.text = "Conditions we currently support"
        subtitleLabel.textColor = theme.secondaryText
        subtitleLabel.numberOfLines = 0
        
        collectionView.backgroundColor = .clear
        
        infoImageView.image = UIImage(systemName: "info.circle")
        infoImageView.tintColor = theme.secondaryText
        
        conditionsLabel.text = "Your plan is generated from selected conditions, ensuring safety and allowing updates anytime."
        conditionsLabel.numberOfLines = 2
        conditionsLabel.textColor = theme.secondaryText
        
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(theme.buttonText, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        
        nextButton.backgroundColor = theme.buttonGlassBackground
        nextButton.layer.cornerRadius = 18
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = theme.buttonGlassBorder.cgColor
        
        nextButton.layer.shadowColor = theme.shadowMedium.cgColor
        nextButton.layer.shadowOpacity = 0.08
        nextButton.layer.shadowRadius = 8
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        applyGlassEffect(to: nextButton)
        
        nextButton.isEnabled = false
        nextButton.alpha = 0.4
        
        pageControl.numberOfPages = totalPages
        pageControl.currentPage = pageIndex
        pageControl.currentPageIndicatorTintColor = theme.accentPrimary
        pageControl.pageIndicatorTintColor = theme.tertiaryText
        pageControl.backgroundColor = .clear
        
        navigationItem.title = appName
        navigationController?.navigationBar.tintColor = theme.accentPrimary
    }
    
    private func applyGlassEffect(to view: UIView) {
        
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blur)
        
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        blurView.layer.cornerRadius = view.layer.cornerRadius
        blurView.clipsToBounds = true
        
        blurView.isUserInteractionEnabled = false
        
        view.insertSubview(blurView, at: 0)
    }
    
    private func registerCell() {
        collectionView.register(UINib(nibName: "MedicalConditionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "medical_condition_cell")
    }
    
    private func generateLayout() -> UICollectionViewLayout {
        
        UICollectionViewCompositionalLayout { _, _ in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(64))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        }
    }
    
    private func togglePrimary(_ condition: MedicalCondition) {
        
        if condition == .none {
            selectedPrimary = [.none]
        } else {
            selectedPrimary.remove(.none)
            
            if selectedPrimary.contains(condition) {
                selectedPrimary.remove(condition)
            } else {
                selectedPrimary.insert(condition)
            }
        }
        
        collectionView.reloadData()
        
        updateNextButtonState()
    }
    
    private func updateNextButtonState() {
        
        let isValid = !selectedPrimary.isEmpty
        
        nextButton.isEnabled = isValid
        nextButton.alpha = isValid ? 1.0 : 0.4
    }
    
    @IBAction func nextTapped(_ sender: UIButton) {
        
        dataController.updateMedicalCondition(Array(selectedPrimary))
        performSegue(withIdentifier: "onboarding_medical_to_lifestyle", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "onboarding_medical_to_lifestyle" {
            
            if let nav = segue.destination as? UINavigationController,
               let vc = nav.viewControllers.first as? OnboardingLifestyleViewController {
                
                vc.dataController = dataController
                vc.appName = appName
                return
            }
            
            if let vc = segue.destination as? OnboardingLifestyleViewController {
                vc.dataController = dataController
                vc.appName = appName
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

extension OnboardingMedicalConditionViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return primaryConditions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "medical_condition_cell", for: indexPath) as! MedicalConditionCollectionViewCell
        
        let condition = primaryConditions[indexPath.item]
        
        cell.configure(title: condition.rawValue.capitalized, isSelected: selectedPrimary.contains(condition), theme: dataController.theme)
        
        return cell
    }
}

extension OnboardingMedicalConditionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        togglePrimary(primaryConditions[indexPath.item])
    }
}
