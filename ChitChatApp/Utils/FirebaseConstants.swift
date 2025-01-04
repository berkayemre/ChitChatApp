//
//  FirebaseConstants.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 9.11.2024.
//

import Foundation
import Firebase
import FirebaseStorage

enum FirebaseConstants {
    static let StorageRef = Storage.storage().reference()
    private static let DatabaseRef = Database
        .database(url: "https://chitchatapp-973d7-default-rtdb.europe-west1.firebasedatabase.app")
        .reference()
    static let UserRef = DatabaseRef.child("users")
    static let ChannelsRef = DatabaseRef.child("channels")
    static let MessagesRef = DatabaseRef.child("channel-messages")
    static let UserChannelsRef = DatabaseRef.child("user-channels")
    static let UserDirectChannels = DatabaseRef.child("user-direct-channels")
}
