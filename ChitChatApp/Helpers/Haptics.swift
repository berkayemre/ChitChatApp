//
//  Haptics.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 11.01.2025.
//

import Foundation
import UIKit

enum Haptic {
    static func impact(_ style: Style) {
        switch style {
                
            case .light:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            case .medium:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            case .heavy:
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            case .error:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.error)
            case .success:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.success)
            case .warning:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.warning)
        }
    }
    
    enum Style {
        case light
        case medium
        case heavy
        case error
        case success
        case warning
    }
}
