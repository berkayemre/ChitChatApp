//
//  UIWindowScene+Extensions.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 6.01.2025.
//

import Foundation
import UIKit

extension UIWindowScene {
    
    static var current: UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first { $0 is UIWindowScene } as? UIWindowScene
    }
    
    var screenHeight: CGFloat {
        return UIWindowScene.current?.screen.bounds.height ?? 0
    }
    
    var screenWidth: CGFloat {
        return UIWindowScene.current?.screen.bounds.width ?? 0
    }
}
