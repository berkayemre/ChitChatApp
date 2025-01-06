//
//  UIApplication+Extensions.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 6.01.2025.
//

import Foundation
import UIKit

extension UIApplication {
    static func dismissKeyboard() {
        UIApplication
            .shared
            .sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
