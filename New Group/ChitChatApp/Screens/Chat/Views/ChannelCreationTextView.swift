//
//  ChannelCreationTextView.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 27.12.2024.
//

import SwiftUI

struct ChannelCreationTextView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        return colorScheme == .dark ? Color.black : Color.yellow
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            (
                Text(Image(systemName: "lock.fill"))
                +
                Text(" Messages and calls are end-to-end encrypted, No one outside of this chat, not even ChitChatApp, can read and listen to them.")
                +
                Text(" Learn more.")
                    .bold()
            )
        }
        .font(.footnote)
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(backgroundColor.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 30)
    }
}

#Preview {
    ChannelCreationTextView()
}
