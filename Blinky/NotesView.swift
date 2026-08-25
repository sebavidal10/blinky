//
//  NotesView.swift
//  Blinky
//
//  Created by Sebastián Vidal Aedo on 17-03-17.
//

import SwiftUI

struct NotesView: View {
    @ObservedObject var notesManager = NotesManager.shared
    @State private var newNoteText: String = ""
    @State private var isNewNoteProtected: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var noteToDelete: QuickNote? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ViewHeader(title: Localization.notesTitle, rightContent: {
                if !notesManager.notes.isEmpty {
                    HStack(spacing: 6) {
                        Button(action: handleGlobalLockToggle) {
                            Image(systemName: notesManager.areAnyLockedNotesBlurred ? "lock.fill" : "lock.open.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(notesManager.areAnyLockedNotesBlurred ? .orange : .green)
                                .frame(width: 26, height: 26)
                                .background(notesManager.areAnyLockedNotesBlurred ? Color.orange.opacity(0.12) : Color.green.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(notesManager.areAnyLockedNotesBlurred ? Localization.unlockAllNotes : Localization.lockAllNotes)
                    }
                }
            })
            
            // New Note Input
            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    if newNoteText.isEmpty {
                        Text(Localization.typeSomething)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $newNoteText)
                        .font(.system(size: 13, weight: .medium))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 40, maxHeight: 120)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(12)
                        .focused($isInputFocused)
                }
                
                VStack(spacing: 6) {
                    Button(action: {
                        isNewNoteProtected.toggle()
                    }) {
                        Image(systemName: isNewNoteProtected ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isNewNoteProtected ? .orange : .green)
                            .frame(width: 28, height: 28)
                            .background(isNewNoteProtected ? Color.orange.opacity(0.15) : Color.green.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(isNewNoteProtected ? Localization.lockedNotePlaceholder : Localization.lockNote)
                    
                    Button(action: addNote) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(newNoteText.isEmpty ? .secondary.opacity(0.3) : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(newNoteText.isEmpty)
                }
                .padding(.bottom, 6)
            }
            .padding(16)
            
            if notesManager.notes.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text(Localization.noNotes)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(notesManager.notes) { note in
                            NoteRow(note: note) {
                                noteToDelete = note
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            isInputFocused = true
        }
        .confirmationDialog(
            Localization.at("Are you sure?", "¿Estás seguro?"),
            isPresented: Binding(
                get: { noteToDelete != nil },
                set: { if !$0 { noteToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(Localization.at("Delete", "Eliminar"), role: .destructive) {
                if let note = noteToDelete {
                    withAnimation {
                        notesManager.deleteNote(id: note.id)
                    }
                }
                noteToDelete = nil
            }
            Button(Localization.at("Cancel", "Cancelar"), role: .cancel) {
                noteToDelete = nil
            }
        } message: {
            Text(Localization.at("This action cannot be undone.", "Esta acción no se puede deshacer."))
        }
    }
    
    private func addNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                notesManager.addNote(trimmed, isLocked: isNewNoteProtected)
                newNoteText = ""
                isNewNoteProtected = false
            }
        }
    }
    
    private func handleGlobalLockToggle() {
        if notesManager.areAnyLockedNotesBlurred {
            // Authenticate to unlock
            BiometricAuthManager.shared.authenticate(reason: Localization.authReasonAllNotes) { success in
                if success {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        notesManager.unlockAll()
                    }
                }
            }
        } else {
            // Lock all notes marked as locked, or if none, protect all notes
            withAnimation(.easeInOut(duration: 0.25)) {
                if notesManager.hasLockedNotes {
                    notesManager.lockAll()
                } else {
                    notesManager.setAllNotesLocked(true)
                }
            }
        }
    }
}

struct NoteRow: View {
    let note: QuickNote
    @ObservedObject var notesManager = NotesManager.shared
    @State private var copied = false
    let onDelete: () -> Void
    
    var isBlurred: Bool {
        notesManager.isNoteBlurred(note: note)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if isBlurred {
                    Text(note.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.disabled)
                        .blur(radius: 7)
                        .opacity(0.35)
                        .allowsHitTesting(false)
                    
                    Button(action: authenticateAndUnlock) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(Localization.tapToUnlock)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.8))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(note.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(NoteRow.formatter.string(from: note.date))
                        .font(.system(size: 10))
                }
                .foregroundColor(.secondary.opacity(0.6))
                
                Spacer()
                
                // Toggle Lock/Protected Button (All in open green when unlocked, orange when locked/blurred)
                Button(action: handleLockToggle) {
                    Image(systemName: isBlurred ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isBlurred ? .orange : .green)
                        .frame(width: 22, height: 22)
                        .background(isBlurred ? Color.orange.opacity(0.12) : Color.green.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isBlurred ? Localization.unlockNote : Localization.lockNote)
                
                // Copy Button (Only visible when not blurred)
                if !isBlurred {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(note.text, forType: .string)
                        withAnimation {
                            copied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                copied = false
                            }
                        }
                    }) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(copied ? .green : .secondary.opacity(0.8))
                            .frame(width: 22, height: 22)
                            .background(Color.primary.opacity(copied ? 0.08 : 0.04))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(Localization.at("Copy note text", "Copiar texto de la nota"))
                }
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 22, height: 22)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(Localization.at("Delete note", "Eliminar nota"))
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
        .contextMenu {
            if note.isLocked {
                Button(action: {
                    withAnimation {
                        notesManager.setNoteLockState(id: note.id, isLocked: false)
                    }
                }) {
                    Label(Localization.at("Remove protection", "Quitar protección"), systemImage: "lock.open")
                }
            } else {
                Button(action: {
                    withAnimation {
                        notesManager.setNoteLockState(id: note.id, isLocked: true)
                    }
                }) {
                    Label(Localization.at("Protect note with Touch ID", "Proteger nota con Touch ID"), systemImage: "lock.fill")
                }
            }
            
            Button(role: .destructive, action: onDelete) {
                Label(Localization.at("Delete", "Eliminar"), systemImage: "trash")
            }
        }
    }
    
    private func handleLockToggle() {
        if isBlurred {
            authenticateAndUnlock()
        } else {
            // When currently unlocked, clicking locks it (sets isLocked = true, saves to UserDefaults, and blurs)
            withAnimation(.easeInOut(duration: 0.2)) {
                if !note.isLocked {
                    notesManager.setNoteLockState(id: note.id, isLocked: true)
                } else {
                    notesManager.lockNote(id: note.id)
                }
            }
        }
    }
    
    private func authenticateAndUnlock() {
        BiometricAuthManager.shared.authenticate(reason: Localization.authReasonNote) { success in
            if success {
                withAnimation(.easeInOut(duration: 0.25)) {
                    notesManager.unlockNote(id: note.id)
                }
            }
        }
    }
    
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        f.locale = Locale(identifier: Localization.resolvedLanguage == "es" ? "es_ES" : "en_US")
        return f
    }()
}

#Preview {
    NotesView()
}
