//
//  TimeInterval+Extensions.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 4.01.2025.
//

import Foundation

extension TimeInterval {
    
    var formatElapsedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    static var stubTimeInterval: TimeInterval {
        return TimeInterval()
    }
}
