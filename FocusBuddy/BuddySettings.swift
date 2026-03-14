//
//  BuddySettings.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation
import Combine

enum BuddyType: String, CaseIterable, Identifiable {
    case robot = "robot"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .robot: return "Robot"
        }
    }

    var emoji: String {
        switch self {
        case .robot: return "🤖"
        }
    }
}

class BuddySettings: ObservableObject {
    static let shared = BuddySettings()

    @Published var selectedBuddy: BuddyType = .robot {
        didSet { UserDefaults.standard.set(selectedBuddy.rawValue, forKey: "selectedBuddy") }
    }

    @Published var buddySize: Double = 1.0 {
        didSet { UserDefaults.standard.set(buddySize, forKey: "buddySize") }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedBuddy"),
           let buddy = BuddyType(rawValue: saved) {
            selectedBuddy = buddy
        }
        let savedSize = UserDefaults.standard.double(forKey: "buddySize")
        if savedSize > 0 { buddySize = savedSize }
    }
}
