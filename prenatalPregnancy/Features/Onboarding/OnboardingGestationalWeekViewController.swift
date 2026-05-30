//
//  OnboardingGestationalWeekViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 09/02/26.
//

import UIKit

class OnboardingGestationalWeekViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateHelpLabel: UILabel!
    @IBOutlet weak var trimesterLabel: UILabel!
    @IBOutlet weak var calculationSegmentedControl: UISegmentedControl!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var dataController: DataController!
    var appName: String = "Blooma"
    
    var pageIndex: Int = 2
    var totalPages: Int = 5
    
    private enum DateMode {
        case lmp
        case edd
    }
    
    private var selectedMode: DateMode {
        calculationSegmentedControl.selectedSegmentIndex == 0 ? .lmp : .edd
    }
    private var isRestoringSavedDates = false
    
    private var currentCalculation: PregnancyDateCalculation {
        switch selectedMode {
        case .lmp:
            return PregnancyDateCalculation.fromLMP(datePicker.date)
        case .edd:
            return PregnancyDateCalculation.fromEDD(datePicker.date)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreSavedDateValues()
    }
    
    private func configureUI() {
        
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        
        titleLabel.text = "Pregnancy dates"
        titleLabel.textColor = theme.primaryText
        
        trimesterLabel.textColor = theme.secondaryText
        trimesterLabel.numberOfLines = 2
        
        dateHelpLabel.textColor = theme.secondaryText
        dateHelpLabel.numberOfLines = 0
        
        calculationSegmentedControl.selectedSegmentIndex = 0
        calculationSegmentedControl.setTitle("LMP", forSegmentAt: 0)
        calculationSegmentedControl.setTitle("EDD", forSegmentAt: 1)
        calculationSegmentedControl.selectedSegmentTintColor = theme.accentPrimary.withAlphaComponent(0.18)
        calculationSegmentedControl.backgroundColor = theme.buttonGlassBackground
        calculationSegmentedControl.setTitleTextAttributes([
            .foregroundColor: theme.secondaryText,
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ], for: .normal)
        calculationSegmentedControl.setTitleTextAttributes([
            .foregroundColor: theme.accentPrimary,
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ], for: .selected)
        
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.backgroundColor = .clear
        datePicker.tintColor = theme.accentPrimary
        
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
        updateDateHelpText(animated: false)
    }
    
    private func restoreSavedDateValues() {
        dataController.loadProfileFromFirestore { [weak self] _ in
            DispatchQueue.main.async {
                self?.setDefaultDateValues()
            }
        }
    }

    private func setDefaultDateValues() {
        isRestoringSavedDates = true
        let profile = dataController.userProfile
        let calendar = Calendar.current
        let defaultLMP = profile.lmpDate ?? PregnancyDateCalculation.estimatedLMP(
            fromWeek: profile.gestationalWeek,
            day: profile.gestationalDay,
            calendar: calendar
        )
        
        calculationSegmentedControl.selectedSegmentIndex = 0
        configureDatePickerLimits(animated: false)
        datePicker.date = min(defaultLMP, Date())
        updatePregnancySummary(animated: false)
        isRestoringSavedDates = false
    }
    
    private func configureDatePickerLimits(animated: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch selectedMode {
        case .lmp:
            datePicker.minimumDate = calendar.date(byAdding: .day, value: -294, to: today)
            datePicker.maximumDate = today
        case .edd:
            datePicker.minimumDate = today
            datePicker.maximumDate = calendar.date(byAdding: .day, value: 294, to: today)
        }
        
        if let minimumDate = datePicker.minimumDate, datePicker.date < minimumDate {
            datePicker.setDate(minimumDate, animated: animated)
        }
        
        if let maximumDate = datePicker.maximumDate, datePicker.date > maximumDate {
            datePicker.setDate(maximumDate, animated: animated)
        }
    }
    
    private func updatePregnancySummary(animated: Bool) {
        let calculation = currentCalculation
        let text = "\(calculation.gestationalDisplay)\n\(calculation.trimester.displayTitle)"
        
        guard animated else {
            trimesterLabel.text = text
            return
        }
        
        UIView.transition(with: trimesterLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.trimesterLabel.text = text
        }
    }
    
    private func updateDateHelpText(animated: Bool) {
        let text: String
        
        switch selectedMode {
        case .lmp:
            text = "LMP is the first day of your last period."
        case .edd:
            text = "EDD is your expected due date."
        }
        
        guard animated else {
            dateHelpLabel.text = text
            return
        }
        
        UIView.transition(with: dateHelpLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.dateHelpLabel.text = text
        }
    }
    
    private func animateSelectionChange() {
        UIView.animate(withDuration: 0.14, animations: {
            self.calculationSegmentedControl.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.18) {
                self.calculationSegmentedControl.transform = .identity
            }
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
    
    @IBAction func calculationModeChanged(_ sender: UISegmentedControl) {
        let previousCalculation: PregnancyDateCalculation
        
        switch selectedMode {
        case .lmp:
            previousCalculation = PregnancyDateCalculation.fromEDD(datePicker.date)
        case .edd:
            previousCalculation = PregnancyDateCalculation.fromLMP(datePicker.date)
        }
        
        configureDatePickerLimits(animated: true)
        
        switch selectedMode {
        case .lmp:
            datePicker.setDate(previousCalculation.lmpDate, animated: true)
        case .edd:
            datePicker.setDate(previousCalculation.eddDate, animated: true)
        }
        
        animateSelectionChange()
        updatePregnancySummary(animated: true)
        updateDateHelpText(animated: true)
        persistCurrentCalculationIfNeeded()
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        updatePregnancySummary(animated: true)
        persistCurrentCalculationIfNeeded()
    }

    private func persistCurrentCalculationIfNeeded() {
        guard !isRestoringSavedDates else { return }
        let calculation = currentCalculation
        dataController.updatePregnancyDates(
            lmpDate: calculation.lmpDate,
            eddDate: calculation.eddDate,
            gestationalWeek: calculation.gestationalWeek,
            gestationalDay: calculation.gestationalDay,
            trimester: calculation.trimester
        )
    }
    
    @IBAction func nextTapped(_ sender: UIButton) {
        let calculation = currentCalculation
        
        dataController.updatePregnancyDates(
            lmpDate: calculation.lmpDate,
            eddDate: calculation.eddDate,
            gestationalWeek: calculation.gestationalWeek,
            gestationalDay: calculation.gestationalDay,
            trimester: calculation.trimester
        )
        
        performSegue(withIdentifier: "onboarding_week_to_condition", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "onboarding_week_to_condition" {
            
            if let vc = segue.destination as? OnboardingMedicalConditionViewController {
                vc.dataController = dataController
                vc.appName = appName
            }
            if let nav = segue.destination as? UINavigationController,
               let vc = nav.viewControllers.first as? OnboardingMedicalConditionViewController {
                vc.dataController = dataController
                vc.appName = appName
            }
        }
    }
}
