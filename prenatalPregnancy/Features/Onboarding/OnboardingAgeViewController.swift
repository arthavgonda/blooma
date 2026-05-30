//
//  OnboardingAgeViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 07/02/26.
//

import UIKit

class OnboardingAgeViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var agePickerView: UIPickerView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageIndex: Int = 1
    var totalPages: Int = 5
    
    var dataController: DataController!
    var appName: String = "Blooma"
    
    private let ages = Array(18...45)
    private var selectedAge: Int = 18
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreSavedAge()
    }

    private func restoreSavedAge() {
        dataController.loadProfileFromFirestore { [weak self] _ in
            DispatchQueue.main.async {
                self?.setDefaultPickerValue()
            }
        }
    }
    
    private func configureUI() {
        
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        
        titleLabel.text = "Your age"
        titleLabel.textColor = theme.primaryText
        
        subtitleLabel.text = "For care suited to you"
        subtitleLabel.textColor = theme.secondaryText
        
        agePickerView.delegate = self
        agePickerView.dataSource = self
        agePickerView.backgroundColor = .clear
        agePickerView.alpha = 1.0
        
        agePickerView.subviews.forEach { $0.isHidden = true }
        
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
        
        pageControl.numberOfPages = totalPages
        pageControl.currentPage = pageIndex
        pageControl.currentPageIndicatorTintColor = theme.accentPrimary
        pageControl.pageIndicatorTintColor = theme.tertiaryText
        pageControl.backgroundColor = .clear
        
        navigationItem.title = appName
        navigationController?.navigationBar.tintColor = theme.accentPrimary
        
    }
    
    private func setDefaultPickerValue() {
        
        let defaultAge = dataController.userProfile.age
        
        if let index = ages.firstIndex(of: defaultAge) {
            agePickerView.selectRow(index, inComponent: 0, animated: false)
            selectedAge = defaultAge
        } else {
            agePickerView.selectRow(0, inComponent: 0, animated: false)
            selectedAge = ages[0]
        }
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
    
    @IBAction func nextTapped(_ sender: UIButton) {
        
        dataController.updateUserAge(selectedAge)
        
        performSegue(withIdentifier: "onboarding_dob_to_week", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "onboarding_dob_to_week" {
            
            if let nav = segue.destination as? UINavigationController,
               let vc = nav.viewControllers.first as? OnboardingGestationalWeekViewController {
                
                vc.dataController = dataController
                vc.appName = appName
                return
            }
            
            if let vc = segue.destination as? OnboardingGestationalWeekViewController {
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

extension OnboardingAgeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ages.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let theme = dataController.theme
        let label = (view as? UILabel) ?? UILabel()
        
        label.textAlignment = .center
        label.text = "\(ages[row]) years"
        
        let isSelected = (row == pickerView.selectedRow(inComponent: component))
        
        if isSelected {
            label.textColor = theme.primaryText
            label.font = .systemFont(ofSize: 20, weight: .bold)
        } else {
            label.textColor = theme.primaryText.withAlphaComponent(0.48)
            label.font = .systemFont(ofSize: 18, weight: .regular)
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedAge = ages[row]
        
        pickerView.reloadComponent(component)
    }
    
}
