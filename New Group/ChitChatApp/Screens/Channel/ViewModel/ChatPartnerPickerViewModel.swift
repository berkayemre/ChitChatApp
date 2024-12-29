//
//  ChatPartnerPickerViewModel.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 9.11.2024.
//

import Foundation
import FirebaseAuth

enum ChannelCreationRoute {
    case groupPartnerPicker
    case setUpGroupChat
}

enum ChannelConstants {
    static let maxGroupParticipants = 12
}

enum ChannelCreationError: Error {
    case noChatPartner
    case failedToCreateUniqueIds
}

@MainActor
final class ChatPartnerPickerViewModel: ObservableObject {
    @Published var navStack = [ChannelCreationRoute]()
    @Published var selectedChatPartners = [UserItem]()
    @Published private(set) var users = [UserItem]()
    @Published var errorState: (showError: Bool, errorMessage: String) = (false, "Uh Oh")
    
    private var lastCursor: String?
    
    var showSelectedUsers: Bool {
        return !selectedChatPartners.isEmpty
    }
    
    var disableNextButton: Bool {
        return selectedChatPartners.isEmpty
    }
    
    var isPaginatable: Bool {
        return !users.isEmpty
    }
    
    private var isDirectChannel: Bool {
        return selectedChatPartners.count == 1
    }
    
    
    init() {
        Task {
            await fetchUsers()
        }
    }
    //MARK: - Public Methods
    
    func fetchUsers() async {
        do {
            let userNode = try await UserService.paginateUsers(lastCursor: lastCursor, pageSize: 5)
            var fetchedUsers = userNode.users
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            fetchedUsers = fetchedUsers.filter { $0.uid != currentUid }
            self.users.append(contentsOf: fetchedUsers)
            self.lastCursor = userNode.currentCursor
            print("lastCursor: \(lastCursor ?? "") \(users.count)")
        }catch{
            print("Failed to fetch users in ChatPartnerPickerViewModel")
        }
    }
    
    func deSelectAllChatPartners() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.selectedChatPartners.removeAll()
        }
    }
    
    func handleItemSelection(_ item: UserItem) {
        if isUserSelected(item) {
            guard let index = selectedChatPartners.firstIndex(where: { $0.uid == item.uid }) else { return }
            selectedChatPartners.remove(at: index)
        }else{
            guard selectedChatPartners.count < ChannelConstants.maxGroupParticipants else {
                let errorMessage = "Sorry, We only allow a Maximum of \(ChannelConstants.maxGroupParticipants) participants in a group chat."
                showError(errorMessage)
                return
            }
            selectedChatPartners.append(item)
        }
    }
    
    func isUserSelected(_ user: UserItem) -> Bool {
        let isSelected = selectedChatPartners.contains { $0.uid == user.uid }
        return isSelected
    }
    
    func createDirectChannel(_ chatPartner: UserItem, completion: @escaping (_ newChannel: ChannelItem) -> Void) {
     
        selectedChatPartners.append(chatPartner)

        Task {
            
            if let channelId = await verifyIfDirectChannelExists(with: chatPartner.uid) {
                let snapshot = try await FirebaseConstants.ChannelsRef.child(channelId).getData()
                let channelDict = snapshot.value as! [String: Any]
                var directChannel = ChannelItem(channelDict)
                directChannel.members = selectedChatPartners
                completion(directChannel)
            } else {
                let channelCreation = createChannel(nil)
                switch channelCreation {
                    case .success(let channel):
                        completion(channel)
                    case .failure(let failure):
                        showError("Sorry! Something Went Wrong While We Were Trying to Setup Your Chat")
                        print("Failed to create a direct channel: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    typealias ChannelId = String
    private func verifyIfDirectChannelExists(with chatPartnerId: String) async -> ChannelId? {
        guard let currentUid = Auth.auth().currentUser?.uid,
              let snapshot = try? await FirebaseConstants.UserDirectChannels.child(currentUid).child(chatPartnerId).getData(),
              snapshot.exists()
        else { return nil }
        
        let directMessageDict = snapshot.value as! [String: Bool]
        let channelId = directMessageDict.compactMap { $0.key }.first
        return channelId
    }
    
    func createGroupChannel(_ groupName: String?, completion: @escaping (_ newChannel: ChannelItem) -> Void) {
        let channelCreation = createChannel(groupName)
        switch channelCreation {
            case .success(let channel):
                completion(channel)
            case .failure(let failure):
                showError("Sorry! Something Went Wrong While We Were Trying to Setup Your Group Chat")
                print("Failed to create a group channel: \(failure.localizedDescription)")
        }
    }
    
    private func showError(_ errorMessage: String) {
        errorState.errorMessage = errorMessage
        errorState.showError = true
        
    }
    
    private func createChannel(_ channelName: String?) -> Result<ChannelItem, Error> {
        guard !selectedChatPartners.isEmpty else { return .failure(ChannelCreationError.noChatPartner) }
        
        guard
            let channelId = FirebaseConstants.ChannelsRef.childByAutoId().key,
            let currentUid = Auth.auth().currentUser?.uid,
            let messageId = FirebaseConstants.MessagesRef.childByAutoId().key
        else { return .failure(ChannelCreationError.failedToCreateUniqueIds) }
        
        let timeStamp = Date().timeIntervalSince1970
        var memberUids = selectedChatPartners.compactMap { $0.uid }
        memberUids.append(currentUid)
        
        let newChannelBroadcast = AdminMessageType.channelCreation.rawValue
        
        var channelDict: [String: Any] = [
            .id: channelId,
            .lastMessage: newChannelBroadcast,
            .creationDate: timeStamp,
            .lastMessageTimeStamp: timeStamp,
            .membersUids: memberUids,
            .membersCount: memberUids.count,
            .adminUids: [currentUid],
            .createdBy: currentUid
        ]
        
        if let channelName = channelName, !channelName.isEmptyoOrWhitespace {
            channelDict[.name] = channelName
        }
        
        let messageDict: [String: Any] = [.type: newChannelBroadcast, .timeStamp: timeStamp, .ownerUid: currentUid]
        
        FirebaseConstants.ChannelsRef.child(channelId).setValue(channelDict)
        FirebaseConstants.MessagesRef.child(channelId).child(messageId).setValue(messageDict)
        
        memberUids.forEach { userId in
            FirebaseConstants.UserChannelsRef.child(userId).child(channelId).setValue(true)
        }
        
        if isDirectChannel {
            let chatPartner = selectedChatPartners[0]
            FirebaseConstants.UserDirectChannels.child(currentUid).child(chatPartner.uid).setValue([channelId: true])
            FirebaseConstants.UserDirectChannels.child(chatPartner.uid).child(currentUid).setValue([channelId: true])
            
        }
        
        var newChannelItem = ChannelItem(channelDict)
        newChannelItem.members = selectedChatPartners
        return .success(newChannelItem)
        
    }
}
