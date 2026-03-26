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
    @FocusState private var isInputFocused: Bool
    @State private var noteToDelete: QuickNote? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ViewHeader(title: Localization.notesTitle)
            
            // New Note Input
            VStack(spacing: 12) {
                TextField(Localization.typeSomething, text: $newNoteText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .padding(12)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(10)
                    .focused($isInputFocused)
                    .onSubmit {
                        addNote()
                    }
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
                notesManager.addNote(trimmed)
                newNoteText = ""
            }
        }
    }
}

struct NoteRow: View {
    let note: QuickNote
    @ObservedObject var notesManager = NotesManager.shared
    @State private var isHovering = false
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(formatter.string(from: note.date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            
            Spacer()
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}

#Preview {
    NotesView()
}
