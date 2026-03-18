//
//  NotesManager.swift
//  Blinky
//
//  Created by Sebastián Vidal Aedo on 17-03-17.
//

import Foundation
import Combine

struct QuickNote: Codable, Identifiable {
    let id: UUID
    let text: String
    let date: Date
}

class NotesManager: ObservableObject {
    static let shared = NotesManager()
    
    @Published var notes: [QuickNote] = [] {
        didSet {
            saveNotes()
        }
    }
    
    private init() {
        loadNotes()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name("BlinkyDataImported"), object: nil)
    }
    
    @objc func reloadData() {
        loadNotes()
    }
    
    func addNote(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newNote = QuickNote(id: UUID(), text: text, date: Date())
        notes.insert(newNote, at: 0)
    }
    
    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "quickNotes")
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "quickNotes"),
           let decoded = try? JSONDecoder().decode([QuickNote].self, from: data) {
            notes = decoded
        }
    }
}
