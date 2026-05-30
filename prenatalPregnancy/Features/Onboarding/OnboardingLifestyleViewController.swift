//
//  OnboardingLifestyleViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 07/02/26.
//

import UIKit

class OnboardingLifestyleViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var activityStackView: UIStackView!
    @IBOutlet weak var gentleButton: UIButton!
    @IBOutlet weak var balancedButton: UIButton!
    @IBOutlet weak var activeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageIndex: Int = 4
    var totalPages: Int = 5
    
    var dataController: DataController!
    var appName: String = "Blooma"
    
    private var selectedActivity: ActivityLevel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreSavedActivityLevel()
    }

    private func restoreSavedActivityLevel() {
        dataController.loadProfileFromFirestore { [weak self] profile in
            guard let self, let profile else { return }
            DispatchQueue.main.async {
                self.applySavedActivityLevel(profile.activityLevel)
            }
        }
    }
    
    private func configureUI() {
        
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        
        titleLabel.text = "Your past activity level"
        titleLabel.textColor = theme.primaryText
        
        subtitleLabel.text = "We adjust based on your activity"
        subtitleLabel.textColor = theme.secondaryText
        subtitleLabel.numberOfLines = 0
        
        configureOptionButton(gentleButton, title: "Gentle", description: "Easy routines focused on your comfort.")
        configureOptionButton(balancedButton, title: "Balanced", description: "Gently progressing routines at your pace.")
        configureOptionButton(activeButton, title: "Active", description: "Elevated routines with trusted expert guidance.")
        
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
    
    private func configureOptionButton(_ button: UIButton, title: String, description: String) {
        button.contentHorizontalAlignment = .leading
        
        button.layer.cornerRadius = 20
        button.layer.shadowOpacity = 0
        applyActivityButtonStyle(button, title: title, description: description, selected: false)
        
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
    @IBAction func activityTapped(_ sender: UIButton) {
        resetSelection()
        
        if sender == gentleButton {
            selectedActivity = .low
            applyActivityButtonStyle(sender, title: "Gentle", description: "Low-impact movement for sensitive days.", selected: true)
        } else if sender == balancedButton {
            selectedActivity = .moderate
            applyActivityButtonStyle(sender, title: "Balanced", description: "Gently progressing routines at your pace.", selected: true)
        } else if sender == activeButton {
            selectedActivity = .high
            applyActivityButtonStyle(sender, title: "Active", description: "Elevated routines with trusted expert guidance.", selected: true)
        }
        
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }

    private func applySavedActivityLevel(_ level: ActivityLevel) {
        resetSelection()
        selectedActivity = level

        switch level {
        case .low:
            applyActivityButtonStyle(gentleButton, title: "Gentle", description: "Low-impact movement for sensitive days.", selected: true)
        case .moderate:
            applyActivityButtonStyle(balancedButton, title: "Balanced", description: "Gently progressing routines at your pace.", selected: true)
        case .high:
            applyActivityButtonStyle(activeButton, title: "Active", description: "Elevated routines with trusted expert guidance.", selected: true)
        }

        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }
    
    private func resetSelection() {
        applyActivityButtonStyle(gentleButton, title: "Gentle", description: "Low-impact movement for sensitive days.", selected: false)
        applyActivityButtonStyle(balancedButton, title: "Balanced", description: "Gently progressing routines at your pace.", selected: false)
        applyActivityButtonStyle(activeButton, title: "Active", description: "Elevated routines with trusted expert guidance.", selected: false)
    }

    private func applyActivityButtonStyle(_ button: UIButton, title: String, description: String, selected: Bool) {
        let theme = dataController.theme
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6

        let attributed = NSMutableAttributedString(string: "\(title)\n\(description)", attributes: [.paragraphStyle: paragraph])
        attributed.addAttributes(
            [.font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: selected ? theme.primaryText : theme.secondaryText],
            range: NSRange(location: 0, length: title.count)
        )
        attributed.addAttributes(
            [.font: UIFont.systemFont(ofSize: 13, weight: .regular), .foregroundColor: selected ? theme.primaryText : theme.secondaryText],
            range: NSRange(location: title.count + 1, length: description.count)
        )

        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(attributed)
        config.titleAlignment = .leading
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        button.configuration = config
        button.backgroundColor = selected ? theme.accentPrimary.withAlphaComponent(0.12) : theme.glassMedium
        button.layer.borderWidth = selected ? 2 : 1
        button.layer.borderColor = selected ? theme.accentPrimary.cgColor : theme.glassBorderStrong.withAlphaComponent(0.45).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
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
        
        guard let activity = selectedActivity else { return }
        
        dataController.updateActivityLevel(activity)
        performSegue(withIdentifier: "onboarding_lifestyle_to_time_to_watch", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "onboarding_lifestyle_to_time_to_watch" {
            
            if let nav = segue.destination as? UINavigationController,
               let vc = nav.viewControllers.first as? ConnectToHealthViewController {

                vc.dataController = dataController
                vc.appName = appName
                return
            }
            
            if let vc = segue.destination as? ConnectToHealthViewController {
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
