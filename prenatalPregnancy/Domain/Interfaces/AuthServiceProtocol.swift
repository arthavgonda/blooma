//
//  AuthServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol AuthServiceProtocol: AnyObject {
    func checkUserExists(username: String, completion: @escaping (Bool, [String: Any]?) -> Void)
    func loginWithUsername(
        credentials: LoginCredentials,
        completion: @escaping (Result<UserProfile, LoginError>, AuthState) -> Void
    )
    func logout()
}
