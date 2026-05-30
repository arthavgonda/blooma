//
//  OnboardingNameViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 07/02/26.
//

import UIKit

class OnboardingUserCredentialsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageIndex: Int = 0
    var totalPages: Int = 5
    
    var dataController: DataController!
    var appName: String = "Blooma"
    
    var theme: AppTheme!
    
    private var greetingTimer: Timer?
    private var greetingIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.theme = dataController.theme
        
        configureUI()
        startGreetingRotation()
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        setupKeyboardDismiss()
        registerForKeyboardNotifications()
        navigationItem.hidesBackButton = true
        
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreSavedCredentials()
    }

    private func restoreSavedCredentials() {
        dataController.loadProfileFromFirestore { [weak self] profile in
            guard let self, let profile else { return }
            DispatchQueue.main.async {
                self.usernameTextField.text = profile.userName
                self.textFieldEditingChanged(self.usernameTextField)
            }
        }
    }
    
    private func configureUI() {
        applyAnimatedBackground(theme: theme)
        
        titleLabel.text = "Create Account"
        subtitleLabel.text = "Set your username & password"
        
        greetingLabel.text = dataController.onboardingGreeting(at: greetingIndex)
        
        titleLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.secondaryText
        greetingLabel.textColor = theme.secondaryText
        
        // Labels
        usernameLabel.text = "Username"
        passwordLabel.text = "New Password"
        confirmPasswordLabel.text = "Confirm Password"
        
        usernameLabel.textColor = theme.primaryText
        passwordLabel.textColor = theme.primaryText
        confirmPasswordLabel.textColor = theme.primaryText
        
        // TextFields
        setupGlassTextField(usernameTextField)
        setupGlassTextField(passwordTextField)
        setupGlassTextField(confirmPasswordTextField)
        
        usernameTextField.textContentType = .username
        
        passwordTextField.textContentType = .newPassword
        passwordTextField.isSecureTextEntry = true
        
        confirmPasswordTextField.textContentType = .newPassword
        confirmPasswordTextField.isSecureTextEntry = true
        
        // Button
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
    
    private func setupGlassTextField(_ textField: UITextField) {
        
        textField.textColor = theme.primaryText
        textField.tintColor = theme.accentSecondary
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.backgroundColor = theme.inputGlassBackground
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: theme.secondaryText.withAlphaComponent(0.75)]
            )
        }
        
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = theme.inputGlassBorder.cgColor
        
        textField.clipsToBounds = true
        
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
        textField.leftView = padding
        textField.leftViewMode = .always
        
        applyGlassEffect(to: textField)
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
    
    private func startGreetingRotation() {
        greetingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            
            self.greetingIndex += 1
            
            UIView.transition(
                with: self.greetingLabel,
                duration: 0.35,
                options: [.transitionCrossDissolve],
                animations: {
                    self.greetingLabel.text = self.dataController.onboardingGreeting(at: self.greetingIndex)
                }
            )
        }
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func registerForKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.3
        let animationOptions = keyboardAnimationOptions(from: userInfo)
        let requestedShift = keyboardHeight * 0.35
        let safeAreaClampedShift = min(requestedShift, maximumAllowedKeyboardShift())

        // Replaced: safe-area-aware movement prevents content from crossing the notch/Dynamic Island.
        navigationController?.setNavigationBarHidden(true, animated: true)
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -safeAreaClampedShift)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        let userInfo = notification.userInfo ?? [:]
        let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.3
        let animationOptions = keyboardAnimationOptions(from: userInfo)

        // Added: restore the navigation bar with the keyboard and return content home.
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions) {
            self.view.transform = .identity
        }
    }

    private func maximumAllowedKeyboardShift() -> CGFloat {
        let topContentY = view.subviews
            .filter { !$0.isHidden && $0.alpha > 0.01 && !($0 is AnimatedBackgroundView) }
            .map { $0.convert($0.bounds, to: view).minY }
            .min() ?? view.safeAreaInsets.top

        return max(0, topContentY - view.safeAreaInsets.top)
    }

    private func keyboardAnimationOptions(from userInfo: [AnyHashable: Any]) -> UIView.AnimationOptions {
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return [.curveEaseInOut, .beginFromCurrentState]
        }

        return [
            UIView.AnimationOptions(rawValue: curveValue << 16),
            .beginFromCurrentState
        ]
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
            
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
            
        } else if textField == confirmPasswordTextField {
            
            textField.resignFirstResponder()
            
            if nextButton.isEnabled {
                nextTapped(nextButton)
            }
        }
        
        return true
    }
    
    private func showAlert(message: String) {
        
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        
        let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""
        
        let isMatch = password == confirmPassword
        let isValid = !username.isEmpty && !password.isEmpty && isMatch
        
        nextButton.isEnabled = isValid
        nextButton.alpha = isValid ? 1.0 : 0.4
        
        confirmPasswordTextField.layer.borderColor = isMatch ?
            UIColor.green.cgColor :
            UIColor.red.cgColor
    }
    
    @IBAction func nextTapped(_ sender: UIButton) {
        
        view.endEditing(true)
        
        let username = usernameTextField.text?.lowercased() ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""
        
        if password != confirmPassword {
            showAlert(message: "Passwords do not match")
            return
        }
        
        if username.isEmpty || password.isEmpty {
            showAlert(message: "Please fill all fields")
            return
        }

        if username == dataController.userProfile.userName.lowercased() {
            dataController.updateUserCredentials(
                username: username,
                password: password
            )

            performSegue(withIdentifier: "onboarding_name_to_age", sender: self)
            return
        }
        
        //CHECK USERNAME EXISTS
        dataController.checkUserExists(username: username) { [weak self] exists, _ in
            
            DispatchQueue.main.async {
                
                guard let self = self else { return }
                
                if exists {
                    self.showAlert(message: "Username already taken. Try another.")
                } else {
                    
                    self.dataController.updateUserCredentials(
                        username: username,
                        password: password
                    )
                    
                    self.performSegue(withIdentifier: "onboarding_name_to_age", sender: self)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "onboarding_name_to_age" {
            
            if let nav = segue.destination as? UINavigationController,
               let vc = nav.viewControllers.first as? OnboardingAgeViewController {
                
                vc.dataController = dataController
                vc.appName = appName
                return
            }
            
            if let vc = segue.destination as? OnboardingAgeViewController {
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
