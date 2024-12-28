//
//  String+Extensions.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 14.11.2024.
//

import Foundation

extension String {
    var isEmptyoOrWhitespace: Bool { return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
