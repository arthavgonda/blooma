//
//  ConnectToHealthViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 10/02/26.
//

import UIKit
import HealthKit
import Lottie

class ConnectToHealthViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var watchAnimationView: LottieAnimationView!
    @IBOutlet weak var allowAccessButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    var dataController: DataController!
    var appName: String = "Prenatal Pregnancy"
    
    private var animationView: LottieAnimationView!
    private var hasRequestedHealthPermission = false
    private var hasShownHealthPermissionFailure = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = appName
        configureUI()
        configureNavigation()
        setupLottie()
        updateHealthConnectionUI()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableSwipeBack()
        restoreSavedWatchConnection()
    }

    private func restoreSavedWatchConnection() {
        dataController.loadProfileFromFirestore { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateHealthConnectionUI()
            }
        }
    }
    
    private func setupLottie() {
        watchAnimationView.backgroundColor = .clear
        animationView = LottieAnimationView(name: "AppleWatchHeartRate")
        animationView.frame = watchAnimationView.bounds
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .loop
        animationView.animationSpeed = 1.0
        
        watchAnimationView.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: watchAnimationView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: watchAnimationView.bottomAnchor),
            animationView.leadingAnchor.constraint(equalTo: watchAnimationView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: watchAnimationView.trailingAnchor)
        ])
        
        animationView.play()
    }
    
    private func configureUI() {
        
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        
        titleLabel.text = "Connect to Health"
        titleLabel.numberOfLines = 0
        
        subtitleLabel.text = "Sync your data for personalized insights."
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        allowAccessButton.setTitle("Allow Access", for: .normal)
        allowAccessButton.setTitleColor(theme.buttonText, for: .normal)
        allowAccessButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        
        allowAccessButton.backgroundColor = theme.buttonGlassBackground
        allowAccessButton.layer.cornerRadius = 18
        allowAccessButton.layer.borderWidth = 1
        allowAccessButton.layer.borderColor = theme.buttonGlassBorder.cgColor
        
        allowAccessButton.layer.shadowColor = theme.shadowMedium.cgColor
        allowAccessButton.layer.shadowOpacity = 0.08
        allowAccessButton.layer.shadowRadius = 8
        allowAccessButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        applyGlassEffect(to: allowAccessButton)
        
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(theme.buttonText, for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        
        skipButton.backgroundColor = theme.buttonGlassBackground
        skipButton.layer.cornerRadius = 18
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = theme.buttonGlassBorder.cgColor
        
        skipButton.layer.shadowColor = theme.shadowMedium.cgColor
        skipButton.layer.shadowOpacity = 0.08
        skipButton.layer.shadowRadius = 8
        skipButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        applyGlassEffect(to: skipButton)
        
    }
    
    private func updateHealthConnectionUI() {
        let isConnected = dataController.userProfile.hasAppleWatch
        
        allowAccessButton.setTitle(isConnected ? "Health Connected" : "Allow Access", for: .normal)
        subtitleLabel.text = isConnected
            ? "Health data is connected for personalized insights."
            : "Sync your data for personalized insights."
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
    
    private func configureNavigation() {
        navigationItem.hidesBackButton = true
    }
    
    private func disableSwipeBack() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    private func showDeniedAlert() {
        guard !hasRequestedHealthPermission else {
            showHealthAccessErrorAlert()
            return
        }
        
        let alert = UIAlertController(
            title: "Permission Required",
            message: "Please allow access to continue.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.requestHealthAccess()
        })
        present(alert, animated: true)
    }
    
    @IBAction func allowAccessTapped(_ sender: UIButton) {
        requestHealthAccess()
    }
    
    private func requestHealthAccess() {
        if dataController.userProfile.hasAppleWatch {
            dataController.updateHasAppleWatch(true)
            performSegue(withIdentifier: "show_Personalization", sender: false)
            return
        }
        
        allowAccessButton.isEnabled = false
        hasRequestedHealthPermission = true
        
        print("Allow Access tapped: starting HealthKit authorization")
        
        dataController.connectAppleWatch { [weak self] success in
            
            guard let self = self else { return }
            self.allowAccessButton.isEnabled = true
            self.updateHealthConnectionUI()
            
            if success {
                self.dataController.updateHasAppleWatch(true)
                self.performSegue(withIdentifier: "show_Personalization", sender: false)
            } else {
                self.showHealthAccessErrorAlert()
            }
        }
    }
    
    private func showHealthAccessErrorAlert() {
        guard !hasShownHealthPermissionFailure else {
            print("HealthKit authorization failed after prompt; staying on fallback UI without repeating popup")
            return
        }
        
        hasShownHealthPermissionFailure = true
        
        let alert = UIAlertController(
            title: "Health Access Unavailable",
            message: "We could not connect to Health right now. You can continue and enable it later from Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.dataController.updateHasAppleWatch(false)
            self?.performSegue(withIdentifier: "show_Personalization", sender: false)
        })
        present(alert, animated: true)
    }
    
    @IBAction func skipTapped(_ sender: UIButton) {
        dataController.updateHasAppleWatch(false)
        performSegue(withIdentifier: "show_Personalization", sender: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "show_Personalization" {
            
            let vc = segue.destination as! PersonalizationViewController
            vc.dataController = self.dataController
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
