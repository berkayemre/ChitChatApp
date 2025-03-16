//
//  AuthProvider.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 8.11.2024.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseDatabase
import StreamVideo

enum AuthState {
    case pending, loggedIn(UserItem), loggedOut
}

protocol AuthProvider {
    static var shared: AuthProvider { get }
    var authState: CurrentValueSubject<AuthState , Never> { get }
    func autoLogin() async
    func login(with email: String, and password: String) async throws
    func createAccount(for username: String, with email: String, and password: String) async throws
    func logout() async throws
}

enum AuthError: Error {
    case accountCreationFailed(_ description: String)
    case failedToSaveUserInfo(_ description: String)
    case emailLoginFailed(_ description: String)
}

extension AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .accountCreationFailed(let description):
                return description
            case .failedToSaveUserInfo(let description):
                return description
            case .emailLoginFailed(let description):
                return description
        }
    }
}

final class AuthManager: AuthProvider {
    
    private init() {
        Task { await autoLogin() }
    }
    
    static let shared: AuthProvider = AuthManager()
    
    var authState = CurrentValueSubject<AuthState, Never>(.pending)
    
    @Published var streamVideo: StreamVideo?
    
    func autoLogin() async {
        if Auth.auth().currentUser == nil {
            authState.send(.loggedOut)
        }else{
            fetchCurrentUserInfo {[weak self] currentUser in
                self?.setUp(currentUser)
            }
        }
    }
    
    func login(with email: String, and password: String) async throws {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            fetchCurrentUserInfo {[weak self] currentUser in
                self?.setUp(currentUser)
            }
            print("Successfully Signed In \(authResult.user.email ?? "")")
        }catch{
            print("Failed to Sign Into the Account with: \(email)")
            throw AuthError.emailLoginFailed(error.localizedDescription)
        }
    }
    
    func createAccount(for username: String, with email: String, and password: String) async throws {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = authResult.user.uid
            let newUser = UserItem(uid: uid, username: username, email: email)
            try await saveUserInfoDatabase(user: newUser)
            setUp(newUser)
        }catch{
            print("Failed to Create an Account:  \(error.localizedDescription)")
            throw AuthError.accountCreationFailed(error.localizedDescription)
        }
    }
    
    func logout() async throws {
        do {
            try Auth.auth().signOut()
            authState.send(.loggedOut)
            print("Successfully logged out!")
        }catch{
            print("Failed to log out current user:  \(error.localizedDescription)")

        }
    }
}

extension AuthManager {
    private func saveUserInfoDatabase(user: UserItem) async throws {
        do {
            let userDictionary: [String: Any] = [.uid: user.uid, .username: user.username, .email: user.email]
            try await FirebaseConstants.UserRef.child(user.uid).setValue(userDictionary)
        }catch{
            print("Failed to Save Created User Info to Database:  \(error.localizedDescription)")
            throw AuthError.failedToSaveUserInfo(error.localizedDescription)
        }
    }
    
    private func fetchCurrentUserInfo(completion: @escaping(UserItem) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        FirebaseConstants.UserRef.child(currentUid).observeSingleEvent(of: .value) { snapshot in
            
            guard let userDict = snapshot.value as? [String: Any] else { return }
            let loggedInUser = UserItem(dictionary: userDict)
            completion(loggedInUser)
            print("\(loggedInUser.username) is logged in")
            print("\(loggedInUser.username)'s fcmToken is \(loggedInUser.fcmToken)")
        }withCancel: { error in
            print("Failed to get current user info")
        }
    }
    
    private func setUp(_ currentUser: UserItem) {
        setUpStreamVideo(for: currentUser)
        authState.send(.loggedIn(currentUser))
    }
}

extension AuthManager {
    private func setUpStreamVideo(for currentUser: UserItem) {
        let apiKey = "mmhfdzb5evj2"
        let user = User(id: "General_Grievous", name: "John")
        let token = UserToken(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3Byb250by5nZXRzdHJlYW0uaW8iLCJzdWIiOiJ1c2VyL0dlbmVyYWxfR3JpZXZvdXMiLCJ1c2VyX2lkIjoiR2VuZXJhbF9Hcmlldm91cyIsInZhbGlkaXR5X2luX3NlY29uZHMiOjYwNDgwMCwiaWF0IjoxNzQxOTQ0OTI0LCJleHAiOjE3NDI1NDk3MjR9.hqjWI7-py_jOAWOA3ksLN_UUB_4r-qeDbwv7rw2C8sI")
        streamVideo = StreamVideo(apiKey: apiKey, user: user, token: token)
    }
}

extension AuthManager {
    
    static let testAccounts: [String] = [
        
        "Test1@test.com",
        "Test2@test.com",
        "Test3@test.com",
        "Test4@test.com",
        "Test5@test.com",
        "Test6@test.com",
        "Test7@test.com",
        "Test8@test.com",
        "Test9@test.com",
        "Test10@test.com",
        "Test11@test.com",
        "Test12@test.com",
        "Test13@test.com",
        "Test14@test.com",
        "Test15@test.com",
        "Test16@test.com",
        "Test17@test.com",
        "Test18@test.com",
        "Test19@test.com",
        "Test20@test.com",
        "Test21@test.com",
        "Test22@test.com",
        "Test23@test.com",
        "Test24@test.com",
        "Test25@test.com",
        "Test26@test.com",
        "Test27@test.com",
        "Test28@test.com",
        "Test29@test.com",
        "Test30@test.com",
        "Test31@test.com",
        "Test32@test.com",
        "Test33@test.com",
        "Test34@test.com",
        "Test35@test.com",
        "Test36@test.com",
        "Test37@test.com",
        "Test38@test.com",
        "Test39@test.com",
        "Test40@test.com",
        "Test41@test.com",
        "Test42@test.com",
        "Test43@test.com",
        "Test44@test.com",
        "Test45@test.com",
        "Test46@test.com",
        "Test47@test.com",
        "Test48@test.com",
        "Test49@test.com",
        "Test50@test.com"
    ]
}

