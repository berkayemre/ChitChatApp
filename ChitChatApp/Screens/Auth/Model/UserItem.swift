//
//  UserItem.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 9.11.2024.
//

import Foundation

struct UserItem: Identifiable, Hashable, Decodable {
    let uid: String
    var username: String
    let email: String
    var bio: String? = nil
    var profileImageUrl: String? = nil
    var fcmToken: String?
    
    var id: String {
        return uid
    }
    
    var bioUnwrapped: String {
        return bio ?? "Hey there! I am using ChitChat"
    }
    
    static let placeholder = UserItem(uid: "1", username: "Emre", email: "emre@mail.com")
    
    static let placeholders: [UserItem] = [
        UserItem(uid: "1", username: "Emre", email: "emre@mail.com"),
        UserItem(uid: "2", username: "Ceren", email: "ceren@mail.com"),
        UserItem(uid: "3", username: "İlayda", email: "ilayda@mail.com"),
        UserItem(uid: "4", username: "Yusuf", email: "yusuf@mail.com"),
        UserItem(uid: "5", username: "Ahmet", email: "ahmet@mail.com"),
        UserItem(uid: "6", username: "Enes", email: "enes@mail.com"),
        UserItem(uid: "7", username: "Kerem", email: "kerem@mail.com"),
        UserItem(uid: "8", username: "Fatih", email: "fatih@mail.com"),
        UserItem(uid: "9", username: "Eda", email: "eda@mail.com"),
        UserItem(uid: "10", username: "Seda", email: "seda@mail.com")
    ]
}

extension UserItem {
    init(dictionary: [String: Any]) {
        self.uid = dictionary[.uid] as? String ?? ""
        self.username = dictionary[.username] as? String ?? ""
        self.email = dictionary[.email] as? String ?? ""
        self.bio = dictionary[.bio] as? String ??  nil
        self.profileImageUrl = dictionary[.profileImageUrl] as? String ?? nil
        self.fcmToken = dictionary[.fcmToken] as? String? ?? nil
    }
}

extension String {
    static let uid = "uid"
    static let username = "username"
    static let email = "email"
    static let bio = "bio"
    static let profileImageUrl = "profileImageUrl"
    static let fcmToken = "fcmToken"
}
