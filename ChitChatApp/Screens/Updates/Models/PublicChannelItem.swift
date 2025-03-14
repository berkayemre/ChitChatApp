//
//  PublicChannelItem.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 14.03.2025.
//

import Foundation

struct PublicChannelItem: Identifiable {
    let imageUrl: String
    let title: String
    
    var id: String {
        return title
    }
    
    static let placeholders: [PublicChannelItem] = [
        .init(imageUrl: "https://1000logos.net/wp-content/uploads/2018/05/PSG-Logo.png", title: "Paris Saint-Germain"),
        .init(imageUrl: "https://static-00.iconduck.com/assets.00/whatsapp-icon-512x511-cfemecku.png", title: "WhatsApp"),
        .init(imageUrl: "https://www.freevector.com/uploads/vector/preview/14053/FreeVector-Real-Madrid-FC.jpg", title: "Real Madrid"),
        .init(imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Call_of_Duty_2023_logo_2.svg/2048px-Call_of_Duty_2023_logo_2.svg.png", title: "Call of Duty"),
        .init(imageUrl: "https://www.bleepstatic.com/content/hl-images/2022/10/27/New_York_Post.jpg", title: "New York Post"),
        .init(imageUrl: "https://1000logos.net/wp-content/uploads/2019/11/The-Wall-Street-Journal-emblem.png", title: "The Wall Street Journal"),
        .init(imageUrl: "https://logos-world.net/wp-content/uploads/2021/11/World-Wrestling-Entertainment-WWE-Logo.png", title: "WWE")
    ]

}
