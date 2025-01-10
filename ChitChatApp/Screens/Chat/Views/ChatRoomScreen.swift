//
//  ChatRoomScreen.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 26.10.2024.
//

import SwiftUI
import PhotosUI

struct ChatRoomScreen: View {
    
    let channel: ChannelItem
    @StateObject private var viewModel: ChatRoomViewModel
    @StateObject private var voiceMessagePlayer = VoiceMessagePlayer()
    
    init(channel: ChannelItem) {
        self.channel = channel
        _viewModel = StateObject(wrappedValue: ChatRoomViewModel(channel))
    }
    
    var body: some View {
        MessageListView(viewModel)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            leadingNavItems()
            trailingNavItems()
        }
        .photosPicker(isPresented: $viewModel.showPhotoPicker,
                      selection: $viewModel.photoPickerItems,
                      maxSelectionCount: 6,
                      photoLibrary: .shared())
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            bottomSafeAreaView()
                .background(Color.whatsAppWhite)
        }
        .animation(.easeInOut, value: viewModel.showPhotoPickerPreview)
        .fullScreenCover(isPresented: $viewModel.videoPlayerState.show) {
            if let player = viewModel.videoPlayerState.player {
                MediaPlayerView(player: player) {
                    viewModel.dismissMediaPlayer()
                }
            }
        }
        .environmentObject(voiceMessagePlayer)
    }
    
    private func bottomSafeAreaView() -> some View {
        VStack(spacing: 0) {
            Divider()
            if viewModel.showPhotoPickerPreview {
                MediaAttachmentPreview(mediaAttachment: viewModel.mediaAttachments) { action in
                    viewModel.handleMediaAttachmentPreview(action)
                }
                Divider()
            }
            
            TextInputArea(textMessage:  $viewModel.textMessage,
                          isRecording: $viewModel.isRecordingVoiceMessage,
                          elapsedTime: $viewModel.elapsedVoiceMessageTime,
                          disableSendButton: viewModel.disableSendButton) { action in
                viewModel.handleTextInputArea(action)
            }
        }
    }
}

extension ChatRoomScreen {
    
    private var channelTitle: String {
        let maxChar = 20
        let trailingChars = channel.title.count > maxChar ? "..." : ""
        let title = String(channel.title.prefix(maxChar) + trailingChars)
        return title
    }
    
    @ToolbarContentBuilder
    private func leadingNavItems() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                CircularProfileImageView(channel, size: .mini)
                
                Text(channelTitle)
                    .bold()
            }
        }
    }
}

extension ChatRoomScreen {
    @ToolbarContentBuilder
    private func trailingNavItems() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button{
                
            }label: {
                Image(systemName: "video")
            }
            
            Button{
                
            }label: {
                Image(systemName: "phone")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatRoomScreen(channel: .placeholder)
    }
}
