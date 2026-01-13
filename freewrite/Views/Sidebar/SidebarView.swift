//
//  SidebarView.swift
//  Flowstate
//
//  Right sidebar showing note history
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    @State private var hoveredEntryId: String?
    @State private var hoveredTrashId: String?
    @State private var hoveredExportId: String?
    @State private var isHoveringHistory = false

    var body: some View {
        let textColor = appState.colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
        let textHoverColor = appState.colorScheme == .light ? Color.black : Color.white

        VStack(spacing: 0) {
            // Header
            headerButton(textColor: textColor, textHoverColor: textHoverColor)

            Divider()

            // Entries List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(appState.notes) { note in
                        noteRow(note: note, textColor: textColor)

                        if note.id != appState.notes.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(.never)
        }
        .frame(width: 200)
        .background(Color(appState.colorScheme == .light ? .white : NSColor.black))
    }

    // MARK: - Header

    @ViewBuilder
    private func headerButton(textColor: Color, textHoverColor: Color) -> some View {
        Button {
            openDocumentsFolder()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("History")
                            .font(.system(size: 13))
                            .foregroundColor(isHoveringHistory ? textHoverColor : textColor)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                            .foregroundColor(isHoveringHistory ? textHoverColor : textColor)
                    }
                    Text(documentsPath)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onHover { hovering in
            isHoveringHistory = hovering
        }
    }

    // MARK: - Note Row

    @ViewBuilder
    private func noteRow(note: Note, textColor: Color) -> some View {
        Button {
            selectNote(note)
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(note.previewText.isEmpty ? "Empty note" : note.previewText)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .foregroundColor(note.previewText.isEmpty ? .secondary : .primary)

                        Spacer()

                        // Action buttons on hover
                        if hoveredEntryId == note.id {
                            actionButtons(for: note)
                        }
                    }

                    Text(note.displayDate)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor(for: note))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredEntryId = hovering ? note.id : nil
            }
        }
        .help("Click to select this entry")
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(for note: Note) -> some View {
        HStack(spacing: 8) {
            // Export PDF button
            Button {
                exportAsPDF(note: note)
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 11))
                    .foregroundColor(hoveredExportId == note.id ?
                        (appState.colorScheme == .light ? .black : .white) :
                        (appState.colorScheme == .light ? .gray : .gray.opacity(0.8)))
            }
            .buttonStyle(.plain)
            .help("Export entry as PDF")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoveredExportId = hovering ? note.id : nil
                }
                updateCursor(hovering: hovering)
            }

            // Delete button
            Button {
                deleteNote(note)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(hoveredTrashId == note.id ? .red : .gray)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoveredTrashId = hovering ? note.id : nil
                }
                updateCursor(hovering: hovering)
            }
        }
    }

    // MARK: - Helpers

    private func backgroundColor(for note: Note) -> Color {
        if note.id == appState.currentNote?.id {
            return Color.gray.opacity(0.1)
        } else if note.id == hoveredEntryId {
            return Color.gray.opacity(0.05)
        } else {
            return Color.clear
        }
    }

    private var documentsPath: String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("Freewrite").path
    }

    private func openDocumentsFolder() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let freewriteFolder = documentsDirectory.appendingPathComponent("Freewrite")
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: freewriteFolder.path)
    }

    private func selectNote(_ note: Note) {
        guard appState.currentNote?.id != note.id else { return }
        appState.selectNote(note)
    }

    private func deleteNote(_ note: Note) {
        appState.deleteNote(note)
    }

    private func exportAsPDF(note: Note) {
        // TODO: Implement PDF export
        print("Export PDF for note: \(note.id)")
    }

    private func updateCursor(hovering: Bool) {
        if hovering {
            NSCursor.pointingHand.push()
        } else {
            NSCursor.pop()
        }
    }
}
