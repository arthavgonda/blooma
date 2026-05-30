//
//  UsernameAuthServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol UsernameAuthServiceProtocol: AnyObject {
    func checkUserExists(username: String, completion: @escaping (Bool, [String: Any]?) -> Void)
    func loginWithUsername(
        credentials: LoginCredentials,
        completion: @escaping (Result<UserProfile, LoginError>, AuthState) -> Void
    )
    func changePassword(old: String, new: String, confirm: String) -> (Bool, String)
}
