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
    var isLocked: Bool
    
    init(id: UUID = UUID(), text: String, date: Date = Date(), isLocked: Bool = false) {
        self.id = id
        self.text = text
        self.date = date
        self.isLocked = isLocked
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, date, isLocked
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        date = try container.decode(Date.self, forKey: .date)
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
    }
}

class NotesManager: ObservableObject {
    static let shared = NotesManager()
    
    @Published var notes: [QuickNote] = [] {
        didSet {
            saveNotes()
        }
    }
    
    // In-memory set of unlocked note IDs (cleared when locking or on app launch)
    @Published var unlockedNoteIDs: Set<UUID> = []
    
    private init() {
        loadNotes()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name("BlinkyDataImported"), object: nil)
    }
    
    @objc func reloadData() {
        loadNotes()
    }
    
    func addNote(_ text: String, isLocked: Bool = false) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newNote = QuickNote(id: UUID(), text: text, date: Date(), isLocked: isLocked)
        notes.insert(newNote, at: 0)
        if !isLocked {
            unlockedNoteIDs.insert(newNote.id)
        }
    }
    
    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        unlockedNoteIDs.remove(id)
    }
    
    func isNoteBlurred(note: QuickNote) -> Bool {
        guard note.isLocked else { return false }
        return !unlockedNoteIDs.contains(note.id)
    }
    
    func toggleNoteLock(id: UUID) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].isLocked.toggle()
            if !notes[index].isLocked {
                unlockedNoteIDs.insert(id)
            } else {
                unlockedNoteIDs.remove(id)
            }
        }
    }
    
    func setNoteLockState(id: UUID, isLocked: Bool) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].isLocked = isLocked
            if !isLocked {
                unlockedNoteIDs.insert(id)
            } else {
                unlockedNoteIDs.remove(id)
            }
        }
    }
    
    func unlockNote(id: UUID) {
        unlockedNoteIDs.insert(id)
    }
    
    func lockNote(id: UUID) {
        unlockedNoteIDs.remove(id)
    }
    
    func lockAll() {
        unlockedNoteIDs.removeAll()
    }
    
    func unlockAll() {
        unlockedNoteIDs = Set(notes.map { $0.id })
    }
    
    var hasLockedNotes: Bool {
        notes.contains { $0.isLocked }
    }
    
    var areAnyLockedNotesBlurred: Bool {
        notes.contains { $0.isLocked && !unlockedNoteIDs.contains($0.id) }
    }
    
    func setAllNotesLocked(_ locked: Bool) {
        for index in notes.indices {
            notes[index].isLocked = locked
        }
        if locked {
            unlockedNoteIDs.removeAll()
        } else {
            unlockedNoteIDs = Set(notes.map { $0.id })
        }
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
