//
//  ChannelItemView.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 26.10.2024.
//

import SwiftUI

struct ChannelItemView: View {
    
    let channel: ChannelItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 10){
            Circle()
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 3){
                titleTextView()
                lastMessagePreview()
            }
        }
    }
    
    private func titleTextView() -> some View {
        HStack{
            Text(channel.title)
                .lineLimit(1)
                .bold()
            
            Spacer()
            
            Text("5:50 PM")
                .foregroundStyle(.gray)
                .font(.system(size: 15))
        }
    }
    
    private func lastMessagePreview() -> some View {
        Text(channel.lastMessage)
            .font(.system(size: 16))
            .lineLimit(1)
            .foregroundStyle(.gray)
    }
}

#Preview {
    ChannelItemView(channel: .placeholder)
}
