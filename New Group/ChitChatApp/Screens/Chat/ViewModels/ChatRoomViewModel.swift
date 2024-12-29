//
//  ChatRoomViewModel.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 23.12.2024.
//

import Foundation
import Combine

final class ChatRoomViewModel: ObservableObject {
    @Published var textMessage = ""
    @Published var messages = [MessageItem]()
    
    private(set) var channel: ChannelItem
    private var currentUser: UserItem?
    private var subscriptions = Set<AnyCancellable>()
    
    
    
    init(_ channel: ChannelItem) {
        self.channel = channel
        listenToAuthState()
    }
    
    deinit {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
        currentUser = nil
    }
    
    private func listenToAuthState() {
        AuthManager.shared.authState.receive(on: DispatchQueue.main).sink {[weak self] authState in
            switch authState {
                    
                case .loggedIn(let currentUser):
                    self?.currentUser = currentUser
                    self?.getMessage()
                default:
                    break
            }
        }.store(in: &subscriptions)
    }
    
    func sendMessage() {
        guard let currentUser else { return }
        MessageService.sendTextMessage(to: channel, from: currentUser, textMessage) {[weak self] in
            self?.textMessage = ""
        }
    }
    
    private func getMessage() {
        MessageService.getMessages(for: channel) {[weak self] messages in
            self?.messages = messages
            print("messages: \(messages.map { $0.text})")
        }
    }
}
