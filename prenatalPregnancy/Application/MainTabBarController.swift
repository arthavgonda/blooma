//
//  MainTabBarController.swift
//  prenatalPregnancy
//
//  Created by GEU on 13/02/26.
//

import UIKit

class MainTabBarController: UITabBarController {

    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()
        injectDataController()
    }

    private func injectDataController() {
        guard let dataController = dataController else {
            assertionFailure("DataController not set on MainTabBarController")
            return
        }

        viewControllers?.forEach { vc in
            if let nav = vc as? UINavigationController {
                nav.viewControllers.forEach { child in
                    
                    if let homeVC = child as? HomeViewController{
                        homeVC.dataController = dataController
                    }

                    if let progressInsightVC = child as? ProgressViewController{
                        progressInsightVC.dataController = dataController
                    }

                    if let routineVC = child as? RoutineViewController {
                        routineVC.dataController = dataController
                    }
                    
                    if let profileVC = child as? ProfileViewController {
                        profileVC.dataController = dataController
                    }
                    
                }
            }
        }
    }
}
