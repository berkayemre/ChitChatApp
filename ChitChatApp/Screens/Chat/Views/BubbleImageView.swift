//
//  BubbleImageView.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 31.10.2024.
//

import SwiftUI
import Kingfisher

struct BubbleImageView: View {
    
    let item: MessageItem
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            if item.direction == .sent { Spacer() }
            
            if item.showGroupPartnerInfo {
                CircularProfileImageView(item.sender?.profileImageUrl, size: .mini)
            }
            
            messageImageView()
                .shadow(color: Color(.systemGray3).opacity(0.1), radius: 5, x: 0, y: 20)
                .overlay(alignment: item.reactionAnchor) {
                    MessageReactionView(message: item)
                        .padding(12)
                        .padding(.bottom, -20)
                }
            
            if item.direction == .received { Spacer() }
            
        }
        .frame(maxWidth: .infinity, alignment: item.alignment)
        .padding(.leading, item.leadingPadding)
        .padding(.trailing, item.trailingPadding)
    }
    
    private func playButton() -> some View {
        Image(systemName: "play.fill")
            .padding()
            .imageScale(.large)
            .foregroundStyle(.gray)
            .background(.thinMaterial)
            .clipShape(Circle())
    }
    
    
    private func messageImageView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            KFImage(URL(string: item.thumbnailUrl ?? ""))
                .resizable()
                .placeholder{ ProgressView() }
                .scaledToFill()
                .frame(width: item.imageSize.width, height: item.imageSize.height)
                .clipShape(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemGray5))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.systemGray5))
                )
                .padding(5)
                .overlay(alignment: .bottomTrailing) {
                    timeStampTextView()
                }
                .overlay {
                    playButton()
                        .opacity(item.type == .video ? 1 : 0)
                    
                }
            
            if !item.text.isEmptyoOrWhitespace {
                Text(item.text)
                    .padding([.horizontal, .bottom], 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(width: item.imageSize.width)
            }
        }
        .background(item.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .applyTail(item.direction)
    }
    
    
    private func sharedButton() -> some View {
        Button{
            
        }label: {
            Image(systemName: "arrowshape.turn.up.right.fill")
                .padding(10)
                .foregroundStyle(.white)
                .background(Color.gray)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
    }
    
    
    private func timeStampTextView() -> some View {
        HStack {
            Text("11.24 AM")
                .font(.system(size: 12))
            
            if item.direction == .sent {
                Image(.seen)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 15, height: 15)
            }
        }
        .padding(.vertical, 2.5)
        .padding(.horizontal, 8)
        .foregroundStyle(.white)
        .background(Color(.systemGray3))
        .clipShape(Capsule())
        .padding(12)
    }
}


#Preview {
    ScrollView {
        BubbleImageView(item: .sentPlaceholder)
        BubbleImageView(item: .receivedPlaceholder)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal)
    .background(Color.gray.opacity(0.4))
}
