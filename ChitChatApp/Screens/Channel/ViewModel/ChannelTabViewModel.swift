//
//  ChannelTabViewModel.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 11.11.2024.
//

import Foundation
import FirebaseAuth

enum ChannelTabRoutes: Hashable {
    case chatRoom(_ channel: ChannelItem)
}

final class ChannelTabViewModel: ObservableObject {
    
    @Published var navRoutes = [ChannelTabRoutes]()
    @Published var navigateToChatRoom = false
    @Published var newChannel: ChannelItem?
    @Published var showChatPartnerPickerView = false
    @Published var channels = [ChannelItem]()
    typealias ChannelId = String
    @Published var channelDictionary: [ChannelId: ChannelItem] = [:]

    private let currentUser: UserItem
    
    init(_ currentUser: UserItem) {
        self.currentUser = currentUser
        fetchCurrentUserChannels()
    }
    
    func onNewChannelCreation(_ channel: ChannelItem) {
        showChatPartnerPickerView = false
        newChannel = channel
        navigateToChatRoom = true
    }
    
    private func fetchCurrentUserChannels() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        FirebaseConstants.UserChannelsRef.child(currentUid).queryLimited(toFirst: 12).observe(.value) {[weak self] snapshot in
            guard let dict = snapshot.value as? [String: Any] else { return }
            dict.forEach { key, value in
                let channelId = key
                let unreadCount = value as? Int ?? 0
                self?.getChannel(with: channelId, unreadCount)
            }
        }withCancel: { error in
            print("Failed to get user's channel Ids: \(error.localizedDescription)")
        }
    }
    
    private func getChannel(with channelId: String, _ unreadCount: Int) {
        FirebaseConstants.ChannelsRef.child(channelId).observe(.value) {[weak self] snapshot in
            guard let dict = snapshot.value as? [String: Any], let self = self else { return }
            var channel = ChannelItem(dict)
            
            if let memCachedChannel = self.channelDictionary[channelId], !memCachedChannel.members.isEmpty {
                channel.members = memCachedChannel.members
                channel.unreadCount = unreadCount
                self.channelDictionary[channelId] = channel
                self.reloadData()
                print("Channel members fetched from cache: \(channel.members.map {$0.username})")
            } else {
                self.getChannelMembers(channel) { members in
                    channel.members = members
                    channel.unreadCount = unreadCount
                    channel.members.append(self.currentUser)
                    self.channelDictionary[channelId] = channel
                    self.reloadData()
    //                self?.channels.append(channel)
                    print("Channel members fetched from database: \(channel.members.map {$0.username})")
                }
            }
        } withCancel: { error in
            print("Failed to get the channel for id \(channelId): \(error.localizedDescription)")
        }
    }
    
    private func getChannelMembers(_ channel: ChannelItem, completion: @escaping (_ members: [UserItem]) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let channelMemberUids = Array(channel.membersUids.filter { $0 != currentUid }.prefix(2))
        UserService.getUsers(with: channelMemberUids) { userNode in
            print("Channel getChannelMembers: \(userNode.users.count)")
            completion(userNode.users)
        }
    }
    
    private func reloadData() {
        self.channels = Array(channelDictionary.values)
        self.channels.sort { $0.lastMessageTimeStamp > $1.lastMessageTimeStamp }
    }
}
