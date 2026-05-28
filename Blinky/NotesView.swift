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
            HStack(alignment: .bottom, spacing: 12) {
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
                
                Button(action: addNote) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(newNoteText.isEmpty ? .secondary.opacity(0.3) : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newNoteText.isEmpty)
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
                notesManager.addNote(trimmed)
                newNoteText = ""
            }
        }
    }
}

struct NoteRow: View {
    let note: QuickNote
    @ObservedObject var notesManager = NotesManager.shared
    @State private var copied = false
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(NoteRow.formatter.string(from: note.date))
                        .font(.system(size: 10))
                }
                .foregroundColor(.secondary.opacity(0.6))
                
                Spacer()
                
                // Copy Button
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
