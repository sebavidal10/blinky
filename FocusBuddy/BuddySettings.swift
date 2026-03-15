//
//  BuddySettings.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation
import Combine

enum BuddyType: String, CaseIterable, Identifiable {
    case robot = "robot"
    case cat = "cat"
    case alien = "alien"
    case turtle = "turtle"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .robot: return "Robot"
        case .cat: return "Gatito"
        case .alien: return "Marciano"
        case .turtle: return "Tortuga"
        }
    }

    var emoji: String {
        switch self {
        case .robot: return "🤖"
        case .cat: return "🐱"
        case .alien: return "👽"
        case .turtle: return "🐢"
        }
    }
    
    var price: Int {
        switch self {
        case .robot: return 0 // Default
        case .cat: return 50
        case .alien: return 150
        case .turtle: return 300
        }
    }

    func emoji(for mood: PetMood) -> String {
        switch self {
        case .robot:
            switch mood {
            case .idle:        return "🤖"
            case .focused:     return "⚙️"
            case .tired:       return "🪫"
            case .celebrating: return "🚀"
            case .sleeping:    return "💤"
            case .typing:      return "🤓"
            case .distracted:  return "🧐"
            case .exhausted:   return "🫠"
            }
        case .cat:
            switch mood {
            case .idle:        return "🐱"
            case .focused:     return "😤"
            case .tired:       return "😩"
            case .celebrating: return "🎉"
            case .sleeping:    return "😴"
            case .typing:      return "🤓"
            case .distracted:  return "🧐"
            case .exhausted:   return "🫠"
            }
        case .alien:
            switch mood {
            case .idle:        return "👽"
            case .focused:     return "🛸"
            case .tired:       return "👾"
            case .celebrating: return "💫"
            case .sleeping:    return "🥱"
            case .typing:      return "🤓"
            case .distracted:  return "🧐"
            case .exhausted:   return "🫠"
            }
        case .turtle:
            switch mood {
            case .idle:        return "🐢"
            case .focused:     return "🥦"
            case .tired:       return "🐚"
            case .celebrating: return "🌊"
            case .sleeping:    return "💤"
            case .typing:      return "🤓"
            case .distracted:  return "🧐"
            case .exhausted:   return "🫠"
            }
        }
    }
}

enum Accessory: String, CaseIterable, Identifiable {
    case none = "ninguno"
    case hat = "sombrero"
    case sunglasses = "gafas"
    case crown = "corona"
    case bowtie = "pajarita"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .none: return ""
        case .hat: return "🎩"
        case .sunglasses: return "🕶️"
        case .crown: return "👑"
        case .bowtie: return "🎀"
        }
    }
    
    var price: Int {
        switch self {
        case .none: return 0
        case .hat: return 30
        case .sunglasses: return 20
        case .crown: return 200
        case .bowtie: return 15
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

    @Published var buddyOpacity: Double = 1.0 {
        didSet { UserDefaults.standard.set(buddyOpacity, forKey: "buddyOpacity") }
    }

    @Published var energyXP: Int = 0 {
        didSet { UserDefaults.standard.set(energyXP, forKey: "energyXP") }
    }

    @Published var energyCoins: Int = 0 {
        didSet { UserDefaults.standard.set(energyCoins, forKey: "energyCoins") }
    }

    @Published var unlockedBuddyIDs: [String] = ["robot"] {
        didSet { UserDefaults.standard.set(unlockedBuddyIDs, forKey: "unlockedBuddyIDs") }
    }

    @Published var unlockedAccessoryIDs: [String] = ["ninguno"] {
        didSet { UserDefaults.standard.set(unlockedAccessoryIDs, forKey: "unlockedAccessoryIDs") }
    }

    @Published var selectedAccessory: Accessory = .none {
        didSet { UserDefaults.standard.set(selectedAccessory.rawValue, forKey: "selectedAccessory") }
    }

    @Published var buddyLevel: Int = 1 {
        didSet { UserDefaults.standard.set(buddyLevel, forKey: "buddyLevel") }
    }

    @Published var isBuddyVisible: Bool = true {
        didSet { UserDefaults.standard.set(isBuddyVisible, forKey: "isBuddyVisible") }
    }

    @Published var justLeveledUp: Bool = false

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedBuddy"),
           let buddy = BuddyType(rawValue: saved) {
            selectedBuddy = buddy
        }
        let savedSize = UserDefaults.standard.double(forKey: "buddySize")
        if savedSize > 0 { buddySize = savedSize }
        
        let savedOpacity = UserDefaults.standard.double(forKey: "buddyOpacity")
        if savedOpacity > 0 { 
            buddyOpacity = savedOpacity 
        } else {
            buddyOpacity = 1.0
        }

        energyXP   = UserDefaults.standard.integer(forKey: "energyXP")
        energyCoins = UserDefaults.standard.integer(forKey: "energyCoins")
        
        if let savedBuddies = UserDefaults.standard.stringArray(forKey: "unlockedBuddyIDs") {
            unlockedBuddyIDs = savedBuddies
        }
        
        if let savedAccs = UserDefaults.standard.stringArray(forKey: "unlockedAccessoryIDs") {
            unlockedAccessoryIDs = savedAccs
        }
        
        if let savedAcc = UserDefaults.standard.string(forKey: "selectedAccessory"),
           let acc = Accessory(rawValue: savedAcc) {
            selectedAccessory = acc
        }

        let savedLevel = UserDefaults.standard.integer(forKey: "buddyLevel")
        buddyLevel = savedLevel > 0 ? savedLevel : 1

        isBuddyVisible = UserDefaults.standard.object(forKey: "isBuddyVisible") as? Bool ?? true
    }

    // MARK: - Progression

    var xpToNextLevel: Int {
        buddyLevel * 100 // Simple linear curve: 100, 200, 300...
    }

    var progressToNextLevel: Double {
        Double(energyXP) / Double(xpToNextLevel)
    }

    func addXP(_ amount: Int) {
        energyXP += amount
        checkLevelUp()
    }

    private func checkLevelUp() {
        if energyXP >= xpToNextLevel {
            energyXP -= xpToNextLevel
            buddyLevel += 1
            triggerLevelUpFeedback()
            checkLevelUp() // Check again in case of multiple levels
        }
    }

    private func triggerLevelUpFeedback() {
        justLeveledUp = true
        NotificationCenter.default.post(name: NSNotification.Name("BuddyLevelUp"), object: nil)
        
        // Reset flag after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.justLeveledUp = false
        }
    }

    // MARK: - Economy

    func addCoins(_ amount: Int) {
        energyCoins += amount
    }

    func canBuyBuddy(_ buddy: BuddyType) -> Bool {
        energyCoins >= buddy.price && !unlockedBuddyIDs.contains(buddy.id)
    }

    func buyBuddy(_ buddy: BuddyType) {
        guard canBuyBuddy(buddy) else { return }
        energyCoins -= buddy.price
        unlockedBuddyIDs.append(buddy.id)
    }

    func canBuyAccessory(_ acc: Accessory) -> Bool {
        energyCoins >= acc.price && !unlockedAccessoryIDs.contains(acc.id)
    }

    func buyAccessory(_ acc: Accessory) {
        guard canBuyAccessory(acc) else { return }
        energyCoins -= acc.price
        unlockedAccessoryIDs.append(acc.id)
    }
}
