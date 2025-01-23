//
//  ReactionPickerView.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 23.01.2025.
//

import SwiftUI
struct EmojiReaction {
    let reaction: Reaction
    var isAnimating: Bool = false
    var opacity: CGFloat = 1
}

struct ReactionPickerView: View {
  
    let message: MessageItem
    
    @State private var animateBackgroundView = false
    @State private var emojiStates: [EmojiReaction] = [
        EmojiReaction(reaction: .like),
        EmojiReaction(reaction: .heart),
        EmojiReaction(reaction: .laugh),
        EmojiReaction(reaction: .shocked),
        EmojiReaction(reaction: .sad),
        EmojiReaction(reaction: .pray),
        EmojiReaction(reaction: .more)
    ]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(emojiStates.enumerated()), id: \.offset) { index, item in
                Text(item.reaction.emoji)
                    .font(.system(size: 30))
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(backgroundView())
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) {
                animateBackgroundView = true
            }
        }
    }
    private func backgroundView() -> some View {
        Capsule()
            .fill(Color.contextMenuTint)
            .mask {
                Capsule()
                    .fill(Color.contextMenuTint)
                    .scaleEffect(animateBackgroundView ? 1 : 0, anchor: message.menuAnchor)
                    .opacity(animateBackgroundView ? 1 : 0)
            }
    }
}

#Preview {
    ReactionPickerView(message: .receivedPlaceholder)
}
