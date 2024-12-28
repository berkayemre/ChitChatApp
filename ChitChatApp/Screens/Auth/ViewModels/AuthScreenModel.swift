//
//  AuthScreenModel.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 6.11.2024.
//

import Foundation

@MainActor
final class AuthScreenModel: ObservableObject {
    
    //MARK: Published Properties
    @Published var isLoading = false
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var errorState: (showError: Bool, errorMessage: String) = (false, "Uh Oh!")
    
    //MARK: Computed Properties
    var disabledLoginButton: Bool {
        return email.isEmpty || password.isEmpty || isLoading
    }
    
    var disabledSignUpButton: Bool {
        return email.isEmpty || password.isEmpty || username.isEmpty || isLoading
    }
    
    func handleSignUp() async {
        
        DispatchQueue.main.async {
              self.isLoading = true
          }
        
        do {
            try await AuthManager.shared.createAccount(for: username, with: email, and: password)
        }catch{
            errorState.errorMessage = "Failed to create an account \(error.localizedDescription)"
            errorState.showError = true
            isLoading = false
        }
    }
    
    func handleLogin() async {
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            try await AuthManager.shared.login(with: email, and: password)
        }catch{
            errorState.errorMessage = "Failed to Login \(error.localizedDescription)"
            errorState.showError = true
            isLoading = false
        }
    }
}
