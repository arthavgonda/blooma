//
//  GoogleAuthServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

protocol GoogleAuthServiceProtocol: AnyObject {
    func signInWithGoogle(
        from viewController: UIViewController,
        completion: @escaping (Result<UserProfile, Error>, AuthState) -> Void
    )
    func signInAsGuest() -> UserProfile
    func logout()
}
