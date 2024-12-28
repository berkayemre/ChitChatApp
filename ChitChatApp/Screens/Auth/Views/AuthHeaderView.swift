//
//  AuthHeaderView.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 5.11.2024.
//

import SwiftUI

struct AuthHeaderView: View {
    var body: some View {
        HStack {
            Image(.whatsapp)
                .resizable()
                .frame(width: 40, height: 40)
           
            Text("ChitChatApp")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    AuthHeaderView()
}
