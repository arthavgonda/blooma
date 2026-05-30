//
//  AuthViewModel.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import FirebaseFirestore
import UIKit

final class AuthViewModel: AuthServiceProtocol {
    private let db: Firestore
    private let profileFirestore: ProfileFirestoreServiceProtocol
    private let dateService: DateServiceProtocol
    private weak var backing: DataControllerBacking?

    init(
        db: Firestore,
        profileFirestore: ProfileFirestoreServiceProtocol,
        dateService: DateServiceProtocol,
        backing: DataControllerBacking?
    ) {
        self.db = db
        self.profileFirestore = profileFirestore
        self.dateService = dateService
        self.backing = backing
    }

    func attach(backing: DataControllerBacking) {
        self.backing = backing
    }

    func signInWithGoogle(
        from viewController: UIViewController,
        completion: @escaping (Result<UserProfile, Error>, AuthState) -> Void
    ) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "GoogleAuth", code: -1)), .existingUser)
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error = error {
                completion(.failure(error), .existingUser)
                return
            }
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "GoogleAuth", code: -2)), .existingUser)
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self else { return }
                if let error = error {
                    completion(.failure(error), .existingUser)
                    return
                }
                guard let firebaseUser = authResult?.user else {
                    let error = NSError(
                        domain: "FirebaseAuth",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "User not found after login"]
                    )
                    completion(.failure(error), .existingUser)
                    return
                }
                let userId = firebaseUser.uid
                self.backing?.currentUserId = userId
                let fallbackProfile = self.createUserProfile(from: firebaseUser)
                self.profileFirestore.onboardingCompleted(userId: userId) { completionFlag in
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set("google", forKey: "loginType")
                        UserDefaults.standard.set(userId, forKey: "userId")

                        if let completionFlag {
                            self.profileFirestore.loadProfileFromFirestore(userId: userId) { profile in
                                let restoredProfile = profile ?? fallbackProfile
                                DispatchQueue.main.async {
                                    self.backing?.userProfile = restoredProfile
                                    self.backing?.isProfileLoaded = true

                                    if completionFlag {
                                        self.backing?.loadProgressFromFirestore {
                                            completion(.success(restoredProfile), .existingUser)
                                        }
                                    } else {
                                        completion(.success(restoredProfile), .newUser)
                                    }
                                }
                            }
                        } else {
                            self.backing?.userProfile = fallbackProfile
                            self.profileFirestore.createUserDocumentIfNeeded(userId: userId, profile: fallbackProfile) {
                                DispatchQueue.main.async {
                                    self.backing?.isProfileLoaded = true
                                    completion(.success(fallbackProfile), .newUser)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func signInAsGuest() -> UserProfile {
        let cal = dateService.istCalendarForProgress
        let today = cal.startOfDay(for: Date())
        guard let sixDaysAgo = cal.date(byAdding: .day, value: -6, to: today) else {
            return guestProfile()
        }
        UserDefaults.standard.set(sixDaysAgo, forKey: "registrationDate")
        let profile = guestProfile()
        backing?.userProfile = profile
        return profile
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Logout error:", error)
        }
        // Setting currentUserId to nil triggers the DataController.didSet which
        // stops the listener and clears all progress + routine state.
        backing?.currentUserId = nil
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "loginType")
        UserDefaults.standard.removeObject(forKey: "userId")
    }

    func checkUserExists(username: String, completion: @escaping (Bool, [String: Any]?) -> Void) {
        fetchUserDocument(field: "userName", identifier: username.lowercased()) { doc in
            guard let doc else {
                completion(false, nil)
                return
            }
            completion(true, self.normalizedUserDocumentData(from: doc.data()))
        }
    }

    func loginWithUsername(
        credentials: LoginCredentials,
        completion: @escaping (Result<UserProfile, LoginError>, AuthState) -> Void
    ) {
        let identifier: String
        let field: String
        if let email = credentials.email, !email.isEmpty {
            identifier = email.lowercased()
            field = "email"
        } else if let username = credentials.username, !username.isEmpty {
            identifier = username.lowercased()
            field = "userName"
        } else {
            completion(.failure(.unknown), .existingUser)
            return
        }
        fetchUserDocument(field: field, identifier: identifier) { [weak self] doc in
            guard let self else { return }
            guard let doc else {
                DispatchQueue.main.async {
                    completion(.failure(.userNotFound), .existingUser)
                }
                return
            }
            let userId = doc.documentID
            let data = self.normalizedUserDocumentData(from: doc.data())
            let storedPassword = data["password"] as? String ?? ""
            if storedPassword != credentials.password {
                completion(.failure(.wrongPassword), .existingUser)
                return
            }
            self.backing?.currentUserId = userId
            UserDefaults.standard.set(userId, forKey: "userId")
            UserDefaults.standard.set(true, forKey: "isLoggedIn") // 🔥 FIX
            UserDefaults.standard.set("username", forKey: "loginType")
            let profile = UserProfile(
                userId: UUID(uuidString: userId) ?? UUID(),
                profileImageData: nil,
                name: data["name"] as? String ?? "",
                email: data["email"] as? String,
                userName: identifier,
                password: storedPassword,
                age: data["age"] as? Int ?? 0,
                lmpDate: self.profileFirestore.dateValue(from: data["lmpDate"]),
                eddDate: self.profileFirestore.dateValue(from: data["eddDate"]),
                gestationalWeek: data["week"] as? Int ?? 1,
                gestationalDay: data["gestationalDay"] as? Int ?? 0,
                trimester: Trimester(rawValue: data["trimester"] as? Int ?? 1) ?? .first,
                medicalConditions: [],
                activityLevel: ActivityLevel(rawValue: data["activityLevel"] as? String ?? "low") ?? .low,
                hasAppleWatch: data["hasAppleWatch"] as? Bool ?? false
            )
            self.backing?.userProfile = profile
            self.backing?.refreshProgressIndexesAfterProfileUpdate()
            self.backing?.loadProgressFromFirestore {
                DispatchQueue.main.async {
                    completion(.success(profile), .existingUser)
                }
            }
        }
    }

    private func guestProfile() -> UserProfile {
        UserProfile(
            userId: UUID(),
            profileImageData: nil,
            name: "Guest",
            email: nil,
            userName: "Mom",
            password: "",
            age: 25,
            lmpDate: nil,
            eddDate: nil,
            gestationalWeek: 1,
            gestationalDay: 0,
            trimester: .first,
            medicalConditions: [],
            activityLevel: .low,
            hasAppleWatch: false
        )
    }

    private func createUserProfile(from user: User) -> UserProfile {
        UserProfile(
            userId: UUID(),
            profileImageData: nil,
            name: user.displayName ?? "",
            email: user.email?.lowercased(),
            userName: (user.email ?? "").lowercased(),
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
    }

    // NEW: Support both legacy top-level auth fields and the current
    // `userDetails.*` Firestore schema used by the app.
    private func normalizedUserDocumentData(from rawData: [String: Any]) -> [String: Any] {
        (rawData["userDetails"] as? [String: Any]) ?? rawData
    }

    // NEW: Username/email login was only checking top-level Firestore fields,
    // so accounts saved under `userDetails.userName` / `userDetails.email`
    // were incorrectly reported as missing.
    private func fetchUserDocument(
        field: String,
        identifier: String,
        completion: @escaping (QueryDocumentSnapshot?) -> Void
    ) {
        let candidateFields = [field, "userDetails.\(field)"]
        fetchUserDocument(in: candidateFields, identifier: identifier, index: 0, completion: completion)
    }

    private func fetchUserDocument(
        in candidateFields: [String],
        identifier: String,
        index: Int,
        completion: @escaping (QueryDocumentSnapshot?) -> Void
    ) {
        guard candidateFields.indices.contains(index) else {
            completion(nil)
            return
        }
        db.collection("users")
            .whereField(candidateFields[index], isEqualTo: identifier)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("User lookup error:", error)
                    completion(nil)
                    return
                }
                if let doc = snapshot?.documents.first {
                    completion(doc)
                    return
                }
                self?.fetchUserDocument(
                    in: candidateFields,
                    identifier: identifier,
                    index: index + 1,
                    completion: completion
                )
            }
    }
}
