//
//  ChatRoomViewModel.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 23.12.2024.
//

import Foundation
import Combine
import PhotosUI
import SwiftUI

final class ChatRoomViewModel: ObservableObject {
    
    @Published var textMessage = ""
    @Published var messages = [MessageItem]()
    @Published var showPhotoPicker: Bool = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var mediaAttachments: [MediaAttachment] = []
    @Published var videoPlayerState: (show: Bool, player: AVPlayer?) = (false, nil)
    @Published var isRecordingVoiceMessage = false
    @Published var elapsedVoiceMessageTime: TimeInterval = 0
    @Published var scrollToBottomRequest: (scroll: Bool, isAnimated: Bool) = (false, false)
    @Published var isPaginating = false
    
    private var firstMessage: MessageItem?
    private var currentPage: String?
    private(set) var channel: ChannelItem
    private var currentUser: UserItem?
    private var subscriptions = Set<AnyCancellable>()
    private let voiceRecorderService = VoiceRecorderService()
    
    var showPhotoPickerPreview: Bool {
        return !mediaAttachments.isEmpty || !photoPickerItems.isEmpty
    }
    
    var disableSendButton: Bool {
        return mediaAttachments.isEmpty && textMessage.isEmpty
    }
    
    private var isPreviewMode: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    init(_ channel: ChannelItem) {
        self.channel = channel
        listenToAuthState()
        onPhotoPickerSelection()
        setUpVoiceRecorderListeners()
        
        if isPreviewMode {
            messages = MessageItem.stubMessages
        }
    }
    
    deinit {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
        currentUser = nil
        voiceRecorderService.tearDown()
    }
    
    private func listenToAuthState() {
        AuthManager.shared.authState.receive(on: DispatchQueue.main).sink {[weak self] authState in
            guard let self = self else { return }
            switch authState {
                case .loggedIn(let currentUser):
                    self.currentUser = currentUser
                    
                    if self.channel.allMembersFetched {
                        self.getHistoricalMessages()
                        print("Channel Members: \(channel.members.map { $0.username })")

                    } else {
                        self.getAllChannelMembers()
                    }
                default:
                    break
            }
        }.store(in: &subscriptions)
    }
    
    private func setUpVoiceRecorderListeners() {
        
        voiceRecorderService.$isRecording.receive(on: DispatchQueue.main).sink { [weak self] isRecording in
                self?.isRecordingVoiceMessage = isRecording
        }.store(in: &subscriptions)
        
        voiceRecorderService.$elapsedTime.receive(on: DispatchQueue.main).sink { [weak self] elapsedTime in
            self?.elapsedVoiceMessageTime = elapsedTime
        }.store(in: &subscriptions)
    }
    
    func sendMessage() {
        if mediaAttachments.isEmpty {
            sendTextMessage(textMessage)
        } else {
            sendMultipleMediaMessages(textMessage, attachments: mediaAttachments)
            clearTextInputArea()
        }
    }
    
private func sendTextMessage(_ text: String) {
        guard let currentUser else { return }
    MessageService.sendTextMessage(to: channel, from: currentUser, text) {[weak self] in
            self?.textMessage = ""
        }
    }
    
    private func clearTextInputArea() {
        textMessage = ""
        mediaAttachments.removeAll()
        photoPickerItems.removeAll()
        UIApplication.dismissKeyboard()
    }
    
    private func sendMultipleMediaMessages(_ text: String, attachments: [MediaAttachment]) {
        for (index, attachment) in attachments.enumerated() {
            let textMessage = index == 0 ? text : ""
            switch attachment.type {
                case .photo:
                    sendPhotoMessage(text: textMessage, attachment)
                case .video:
                    sendVideoMessage(text: textMessage, attachment)
                case .audio:
                    sendVoiceMessage(text: textMessage, attachment)
            }
        }
    }
    
    private func sendPhotoMessage(text: String, _ attachment: MediaAttachment) {
        uploadImageToStorage(attachment) {[weak self] imageUrl in
            guard let self = self, let currentUser else { return }
            print("Uploaded Image to storage")

            let uploadParams = MessageUploadParams(
                channel: channel,
                text: text,
                type: .photo,
                attachment: attachment,
                thumbnailURL: imageUrl.absoluteString,
                sender: currentUser)
            
            MessageService.sendMediaMessage(to: channel, params: uploadParams) { [weak self] in
                self?.scrollToBottom(isAnimated: true)
            }
        }
    }
    
    private func sendVideoMessage(text: String, _ attachment: MediaAttachment) {
        uploadFileToStorage(for: .videoMessage, attachment) {[weak self] videoURL in
            self?.uploadImageToStorage(attachment) {[weak self] thumbnailURL in
                guard let self = self, let currentUser else { return }
                let uploadParams = MessageUploadParams(
                    channel: self.channel,
                    text: text,
                    type: .video,
                    attachment: attachment,
                    thumbnailURL: thumbnailURL.absoluteString,
                    videoURL: videoURL.absoluteString,
                    sender: currentUser)
                MessageService.sendMediaMessage(to: self.channel, params: uploadParams) {[weak self] in
                    self?.scrollToBottom(isAnimated: true)
                }
            }
        }
    }
        
    private func sendVoiceMessage(text: String, _ attachment: MediaAttachment) {
        
        guard let audioDuration = attachment.audioDuration, let currentUser else { return }

        uploadFileToStorage(for: .voiceMessage, attachment) {[weak self] fileURL in
            guard let self else { return }
            let uploadParams = MessageUploadParams(
                channel: self.channel,
                text: text,
                type: .audio,
                attachment: attachment,
                sender: currentUser,
                audioURL: fileURL.absoluteString,
                audioDuration: audioDuration
                )
            MessageService.sendMediaMessage(to: self.channel, params: uploadParams) {[weak self] in
                self?.scrollToBottom(isAnimated: true)
            }
            if !text.isEmptyoOrWhitespace {
                self.sendTextMessage(text)
            }
        }
    }
    
    private func scrollToBottom(isAnimated: Bool) {
        scrollToBottomRequest.scroll = true
        scrollToBottomRequest.isAnimated = isAnimated
    }
    
    private func uploadImageToStorage(_ attachment: MediaAttachment, completion: @escaping(_ imageURL: URL) -> Void) {
        FirebaseHelper.uploadImage(attachment.thumbnail, for: .photoMessage) { result in
            switch result {
                case .success(let imageURL):
                    completion(imageURL)
                case .failure(let error):
                    print("Failed to Upload Image to Storage: \(error.localizedDescription)")
            }
        } progressHandler: { progress in
            print("UPLOAD IMAGE PROGRESS: \(progress)")
        }
    }
    
    private func uploadFileToStorage(for uploadType: FirebaseHelper.UploadType, _ attachment: MediaAttachment, completion: @escaping(_ fileURL: URL) -> Void) {
        guard let fileToUpload = attachment.fileURL else { return }
        FirebaseHelper.uploadFile(for: uploadType, fileURL: fileToUpload) { result in
            switch result {
                case .success(let fileURL):
                    completion(fileURL)
                case .failure(let error):
                    print("Failed to Upload File to Storage: \(error.localizedDescription)")
            }
        } progressHandler: { progress in
            print("UPLOAD FILE PROGRESS: \(progress)")
        }
    }
    
    var isPaginatable: Bool {
        return currentPage != firstMessage?.id
    }
    
    func getHistoricalMessages() {
        isPaginating = currentPage != nil
        MessageService.getHistoricalMessages(for: channel, lastCursor: currentPage, pageSize: 12) {[weak self] messageNode in
            if self?.currentPage == nil {
                self?.getFirstMessage()
                self?.listenForNewMessages()
            }
            self?.messages.insert(contentsOf: messageNode.messages, at: 0)
            self?.currentPage = messageNode.currentCursor
            self?.scrollToBottom(isAnimated: false)
            self?.isPaginating = false
        }
    }
    
    func paginateMoreMessages() {
        guard isPaginatable else {
            isPaginating = false
            return
        }
        getHistoricalMessages()
    }
    
    private func getFirstMessage() {
        MessageService.getFirstMessage(in: channel) {[weak self] firstMessage in
            self?.firstMessage = firstMessage
        }
    }
    
    private func listenForNewMessages() {
        MessageService.listenForNewMessages(in: channel) {[weak self] newMessage in
            self?.messages.append(newMessage)
            self?.scrollToBottom(isAnimated: false)
        }
    }
    
    private func getAllChannelMembers() {
        
        guard let currentUser = currentUser else { return }
        let membersAlreadyFetched = channel.members.compactMap { $0.uid }
        var memberUIDSToFetch = channel.membersUids.filter { !membersAlreadyFetched.contains($0) }
        memberUIDSToFetch = memberUIDSToFetch.filter { $0 != currentUser.uid }
        
        UserService.getUsers(with: memberUIDSToFetch) { [weak self] userNode in
            guard let self = self else { return }
            self.channel.members.append(contentsOf: userNode.users)
            self.getHistoricalMessages()
            print("getAllChannelMembers: \(channel.members.map { $0.username })")
        }
    }
    
    func handleTextInputArea(_ action: TextInputArea.UserAction) {
        switch action {
            case .presentPhotoPicker:
                showPhotoPicker = true
            case .sendMessage:
                sendMessage()
            case .recordAudio:
                toggleAudioRecorder()
        }
    }
    
    private func toggleAudioRecorder() {
        if voiceRecorderService.isRecording {
            voiceRecorderService.stopRecording {[weak self] audioURL, audioDuration in
                self?.createAudioAttachment(from: audioURL, audioDuration)
            }
        } else {
            voiceRecorderService.startRecording()
        }
    }
    
    private func createAudioAttachment(from audioURL: URL?, _ audioDuration: TimeInterval) {
        guard let audioURL = audioURL else { return }
        let id = UUID().uuidString
        let audioAttachment = MediaAttachment(id: id, type: .audio(audioURL, audioDuration))
        mediaAttachments.insert(audioAttachment, at: 0)
    }
    
    private func onPhotoPickerSelection() {
        $photoPickerItems.sink { [weak self] photoItems in
            guard let self = self else { return }
//            self.mediaAttachments.removeAll()
            let audioRecordings = mediaAttachments.filter({ $0.type == .audio(.stubURL, .stubTimeInterval) })
            self.mediaAttachments = audioRecordings
            Task { await self.parsePhotoPickerItems(photoItems) }
        }.store(in: &subscriptions)
    }
    
    private func parsePhotoPickerItems(_ photoPickerItems: [PhotosPickerItem]) async {
        for photoItem in photoPickerItems {
            if photoItem.isVideo {
                if let movie = try? await photoItem.loadTransferable(type: VideoPickerTransferable.self), let thumbnailImage = try? await movie.url.generateVideoThumbnail(), let itemIdentifier = photoItem.itemIdentifier {
                    let videoAttachment = MediaAttachment(id: itemIdentifier, type: .video(thumbnailImage, movie.url))
                    self.mediaAttachments.insert(videoAttachment, at: 0)
                }
            } else {
                guard
                let data = try? await photoItem.loadTransferable(type: Data.self),
                let thumbnail = UIImage(data: data),
                let itemIdentifier = photoItem.itemIdentifier
                else { return }
                let photoAttachment = MediaAttachment(id: itemIdentifier, type: .photo(thumbnail))
                self.mediaAttachments.insert(photoAttachment, at: 0)
            }
        }
    }
    
    func dismissMediaPlayer() {
        videoPlayerState.player?.replaceCurrentItem(with: nil)
        videoPlayerState.player = nil
        videoPlayerState.show = false
    }
    
    func showMediaPlayer(_ fileURL: URL) {
        videoPlayerState.show = true
        videoPlayerState.player = AVPlayer(url: fileURL)
    }
    
    func handleMediaAttachmentPreview(_ action: MediaAttachmentPreview.UserAction) {
        switch action {
            case .play(let attachment):
                guard let fileURL = attachment.fileURL else { return }
                showMediaPlayer(fileURL)
            case .remove(let attachment):
                remove(attachment)
                guard let fileURL = attachment.fileURL else { return }
                if attachment.type == .audio(.stubURL, .stubTimeInterval) {
                    voiceRecorderService.deleteRecording(at: fileURL)
                }
        }
    }
    
    private func remove(_ item: MediaAttachment) {
        guard let attachmentIndex = mediaAttachments.firstIndex(where: { $0.id == item.id}) else { return }
        mediaAttachments.remove(at: attachmentIndex)
        
        guard let photoIndex = photoPickerItems.firstIndex(where: { $0.itemIdentifier == item.id }) else { return }
        photoPickerItems.remove(at: photoIndex)
    }
    
    func isNewDay(for message: MessageItem, at index: Int) -> Bool {
        let priorIndex = max(0, (index - 1))
        let priorMessage = messages[priorIndex]
        return !message.timeStamp.isSameDay(as: priorMessage.timeStamp)
    }
    
    func showSenderName(for message: MessageItem, at index: Int) -> Bool {
        guard channel.isGroupChat else { return false }
        
        let isNewDay = isNewDay(for: message, at: index)
        let priorIndex = max(0, (index - 1))
        let priorMessage = messages[priorIndex]
        
        if isNewDay {
            return !message.isSentByMe
        } else {
            return !message.isSentByMe && !message.containsSameOwner(as: priorMessage)
        }
        
    }
}
