import SwiftUI

struct FavoritesView: View {
    @Environment(ProgramsViewModel.self) private var viewModel
    @State private var selectedProgram: Program?
    @State private var programForStatusEdit: Program?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favoritePrograms.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favoritePrograms) { program in
                                FavoriteCardView(
                                    program: program,
                                    favoriteItem: viewModel.getFavoriteItem(program.id),
                                    onTap: {
                                        selectedProgram = program
                                    },
                                    onFavoriteToggle: {
                                        viewModel.toggleFavorite(program.id)
                                    },
                                    onStatusNotesTap: {
                                        programForStatusEdit = program
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(item: $selectedProgram) { program in
                ProgramDetailView(program: program)
            }
            .sheet(item: $programForStatusEdit) { program in
                StatusNotesSheet(
                    program: program,
                    favoriteItem: viewModel.getFavoriteItem(program.id),
                    onStatusChange: { status in
                        viewModel.updateFavoriteStatus(program.id, status: status)
                    },
                    onNotesChange: { notes in
                        viewModel.updateFavoriteNotes(program.id, notes: notes)
                    }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No favorites yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap the heart icon on any program to save it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Favorite Card View

struct FavoriteCardView: View {
    let program: Program
    let favoriteItem: FavoriteItem?
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void
    let onStatusNotesTap: () -> Void

    private var status: FavoriteStatus {
        favoriteItem?.status ?? .saved
    }

    private var statusColor: Color {
        let c = status.color
        return Color(red: c.red, green: c.green, blue: c.blue)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row with category and favorite button
                HStack {
                    Text(program.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.15), in: Capsule())

                    Text(program.locationText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: onFavoriteToggle) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                // Program name
                Text(program.name)
                    .font(.headline)
                    .lineLimit(2)

                // Description
                Text(program.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Status badge - tappable
                Button(action: onStatusNotesTap) {
                    HStack(spacing: 6) {
                        Image(systemName: status.systemImage)
                            .font(.caption)

                        Text(status.label)
                            .font(.caption)
                            .fontWeight(.medium)

                        if favoriteItem?.hasNotes == true {
                            Image(systemName: "note.text")
                                .font(.caption2)
                        }

                        Spacer()

                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(statusColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Notes preview
                if let notes = favoriteItem?.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Notes Sheet

struct StatusNotesSheet: View {
    let program: Program
    let favoriteItem: FavoriteItem?
    let onStatusChange: (FavoriteStatus) -> Void
    let onNotesChange: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStatus: FavoriteStatus
    @State private var notes: String

    init(program: Program, favoriteItem: FavoriteItem?, onStatusChange: @escaping (FavoriteStatus) -> Void, onNotesChange: @escaping (String?) -> Void) {
        self.program = program
        self.favoriteItem = favoriteItem
        self.onStatusChange = onStatusChange
        self.onNotesChange = onNotesChange
        self._selectedStatus = State(initialValue: favoriteItem?.status ?? .saved)
        self._notes = State(initialValue: favoriteItem?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(program.name)
                        .font(.headline)
                }

                Section("Status") {
                    ForEach(FavoriteStatus.allCases) { status in
                        Button {
                            selectedStatus = status
                        } label: {
                            HStack {
                                let c = status.color
                                Image(systemName: status.systemImage)
                                    .foregroundStyle(Color(red: c.red, green: c.green, blue: c.blue))
                                    .frame(width: 24)

                                Text(status.label)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Private Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)

                    Text("Your notes are stored only on this device and never sent to any server.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Update Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onStatusChange(selectedStatus)
                        onNotesChange(notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    FavoritesView()
        .environment(ProgramsViewModel())
}
