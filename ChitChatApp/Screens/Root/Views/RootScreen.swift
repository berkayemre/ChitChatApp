//
//  RootScreen.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 8.11.2024.
//

import SwiftUI

struct RootScreen: View {
    
    @StateObject private var viewModel = RootScreenModel()
    
    var body: some View {
        switch viewModel.authState {
            case .pending:
                ProgressView()
                    .controlSize(.large)
                
            case .loggedIn(let loggedInUser):
                MainTabView(loggedInUser)
                
            case .loggedOut:
                LoginScreen()
        }
    }
}

#Preview {
    RootScreen()
}
