//
//  BuddySettings.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation
import Combine

class BuddySettings: ObservableObject {
    static let shared = BuddySettings()

    @Published var buddyOpacity: Double = 1.0 {
        didSet { UserDefaults.standard.set(buddyOpacity, forKey: "buddyOpacity") }
    }

    @Published var isBuddyVisible: Bool = true {
        didSet { UserDefaults.standard.set(isBuddyVisible, forKey: "isBuddyVisible") }
    }

    private init() {
        let savedOpacity = UserDefaults.standard.double(forKey: "buddyOpacity")
        if savedOpacity > 0 { 
            buddyOpacity = savedOpacity 
        } else {
            buddyOpacity = 1.0
        }

        isBuddyVisible = UserDefaults.standard.object(forKey: "isBuddyVisible") as? Bool ?? true
    }
}
