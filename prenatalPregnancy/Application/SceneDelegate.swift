//
//  SceneDelegate.swift
//  prenatalPregnancy
//
//  Created by GEU on 30/01/26.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var dataModel: DataController!
    private var pregnancyProgressTimer: Timer?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let firebaseUser = Auth.auth().currentUser
        let isLoggedIn = firebaseUser != nil || UserDefaults.standard.bool(forKey: "isLoggedIn")

        dataModel = DataController(
            userProfile: UserProfile(
                userId: UUID(),
                profileImageData: nil,
                name: "",
                email: nil,
                userName: "",
                password: "",
                age: 0,
                lmpDate: nil,
                eddDate: nil,
                gestationalWeek: 1,
                gestationalDay: 0,
                trimester: .first,
                medicalConditions: [],
                activityLevel: .low,
                hasAppleWatch: false
            )
        )

        if isLoggedIn, let savedUserId = UserDefaults.standard.string(forKey: "userId") {
            dataModel.currentUserId = savedUserId
            bootstrapLoggedInUser(userId: savedUserId, storyboard: storyboard)
        } else {
            showLogin(storyboard: storyboard)
        }

        window.makeKeyAndVisible()
    }

    // MARK: - Bootstrap

    /// Full sequential load: profile → progress → routine snapshot → listener → UI.
    /// This guarantees that today's saved routine is in the local cache BEFORE any
    /// view controller's viewWillAppear fires, preventing stale re-generation.
    private func bootstrapLoggedInUser(userId: String, storyboard: UIStoryboard) {
        dataModel.profileFirestoreService.onboardingCompleted(userId: userId) { [weak self] completed in
            guard let self else { return }
            guard completed == true else {
                DispatchQueue.main.async { self.showLogin(storyboard: storyboard) }
                return
            }

            self.loadCompletedUser(userId: userId, storyboard: storyboard)
        }
    }

    private func loadCompletedUser(userId: String, storyboard: UIStoryboard) {
        dataModel.loadProfileFromFirestore { [weak self] profile in
            guard let self else { return }
            guard let profile else {
                DispatchQueue.main.async { self.showLogin(storyboard: storyboard) }
                return
            }
            self.dataModel.userProfile = profile
            self.dataModel.refreshPregnancyProgressIfNeeded()

            self.dataModel.loadProgressFromFirestore {
                self.dataModel.loadTodayRoutineSnapshot {
                    DispatchQueue.main.async {
                        self.dataModel.startProgressListener()
                        self.schedulePregnancyProgressRefresh()
                        self.showMainApp(storyboard: storyboard)
                    }
                }
            }
        }
    }
    
    func showOnboardingForExistingUser(storyboard: UIStoryboard) {
        showLogin(storyboard: storyboard)  // for now, or route to specific step
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // No-op: pregnancy progress refresh is handled in sceneWillEnterForeground
        // to avoid calling it twice per foreground transition (BUG-015 fix).
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Single authoritative location for pregnancy-progress date refresh.
        dataModel?.refreshPregnancyProgressIfNeeded()
        schedulePregnancyProgressRefresh()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        pregnancyProgressTimer?.invalidate()
        pregnancyProgressTimer = nil
    }


}

private extension SceneDelegate {
    func schedulePregnancyProgressRefresh() {
        pregnancyProgressTimer?.invalidate()

        guard let dataModel else { return }

        pregnancyProgressTimer = Timer.scheduledTimer(withTimeInterval: dataModel.secondsUntilNextISTMidnight(), repeats: false) { [weak self] _ in
            self?.dataModel?.refreshPregnancyProgressIfNeeded()
            self?.schedulePregnancyProgressRefresh()
        }

        if let pregnancyProgressTimer {
            RunLoop.main.add(pregnancyProgressTimer, forMode: .common)
        }
    }
}

extension SceneDelegate {

    func showMainApp(storyboard: UIStoryboard) {

        let tabBarVC = storyboard.instantiateViewController(identifier: "MainTabBarController") as! MainTabBarController
        tabBarVC.dataController = dataModel
        dataModel.requestStartupTrackingPermissions()

        window?.rootViewController = tabBarVC
        window?.installGlobalParticleOverlay(theme: dataModel.theme)
        window?.makeKeyAndVisible()
    }

    func showLogin(storyboard: UIStoryboard) {

        guard let navVC = storyboard.instantiateInitialViewController() as? UINavigationController else { return }

        window?.rootViewController = navVC
        window?.installGlobalParticleOverlay(theme: dataModel.theme)
        window?.makeKeyAndVisible()

        if let loginVC = navVC.topViewController as? OnboardingLoginViewController {
            loginVC.dataController = dataModel
        }
    }
}
