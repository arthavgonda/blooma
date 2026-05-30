//
//  
// AuthenticationModels.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

//Login
enum LoginType: String {
    case google
    case apple
    case guest
}

struct LoginCredentials {
    var username: String?
    var email: String?
    var password: String
}

enum AuthState {
    case newUser
    case existingUser
}

enum LoginError: LocalizedError {
    case userNotFound
    case wrongPassword
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .wrongPassword:
            return "Incorrect password"
        case .unknown:
            return "Something went wrong"
        }
    }
}
