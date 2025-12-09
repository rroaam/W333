//
//  CaptureDetailView.swift
//  Capsule
//
//  Detailed view of a single capture with playback controls,
//  transcript display, and management actions.
//

import SwiftUI

struct CaptureDetailView: View {
    // The capture to display
    let capture: Capture

    // Environment
    @EnvironmentObject var captureStore: CaptureStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var player = AudioPlayer()

    /// Editing mode for transcript
    @State private var isEditingTranscript = false
    @State private var editedTranscript: String = ""

    /// Show delete confirmation
    @State private var showingDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Header with category and time
                    headerSection

                    // Audio player
                    audioPlayerSection

                    // Transcript section
                    transcriptSection

                    // Tags section (if any)
                    if !capture.tags.isEmpty {
                        tagsSection
                    }

                    // Metadata
                    metadataSection

                    Spacer(minLength: DesignSystem.Spacing.xxl)
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.mutedText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: shareCapture) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(action: archiveCapture) {
                            Label("Archive", systemImage: "archivebox")
                        }
                        Divider()
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DesignSystem.Colors.mutedText)
                    }
                }
            }
            .confirmationDialog(
                "Delete this capture?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteCapture()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .onAppear {
            player.load(filename: capture.audioFileName)
            editedTranscript = capture.transcript ?? ""
        }
        .onDisappear {
            player.stop()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    /// Header with title and category
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Category badge
            CategoryBadge(category: capture.category, isActive: false)

            // Title
            Text(capture.displayTitle)
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.primaryText)

            // Relative time
            Text(capture.relativeTimeString)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText)
        }
    }

    /// Audio player controls
    private var audioPlayerSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Waveform visualization (simplified for Phase 1)
            WaveformView(progress: player.progress)
                .frame(height: 60)

            // Time display
            HStack {
                Text(player.currentTime.formatted)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.mutedText)
                    .monospacedDigit()

                Spacer()

                Text(player.duration.formatted)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.mutedText)
                    .monospacedDigit()
            }

            // Playback controls
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Skip back
                Button(action: { player.skipBackward() }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(DesignSystem.Colors.mutedText)
                }

                // Play/Pause
                Button(action: { player.togglePlayback() }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }

                // Skip forward
                Button(action: { player.skipForward() }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(DesignSystem.Colors.mutedText)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    /// Transcript display and editing
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("TRANSCRIPT")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.mutedText)
                    .tracking(1)

                Spacer()

                // Edit button (for future phases with transcription)
                if capture.transcript != nil {
                    Button(action: { isEditingTranscript.toggle() }) {
                        Image(systemName: isEditingTranscript ? "checkmark" : "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.mutedText)
                    }
                }
            }

            if let transcript = capture.transcript {
                if isEditingTranscript {
                    TextEditor(text: $editedTranscript)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .scrollContentBackground(.hidden)
                        .background(DesignSystem.Colors.surface)
                        .frame(minHeight: 100)
                } else {
                    Text(transcript)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            } else {
                // Placeholder for Phase 1 (no transcription yet)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "waveform")
                        .foregroundColor(DesignSystem.Colors.mutedText)
                    Text("Transcription available in a future update")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.mutedText)
                        .italic()
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    /// Tags display
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("TAGS")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText)
                .tracking(1)

            FlowLayout(spacing: DesignSystem.Spacing.xs) {
                ForEach(capture.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(capture.category.color)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(capture.category.color.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    /// Metadata section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("DETAILS")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText)
                .tracking(1)

            VStack(spacing: DesignSystem.Spacing.xs) {
                metadataRow(label: "Duration", value: capture.formattedDuration)
                metadataRow(label: "Created", value: formatDate(capture.createdAt))
                metadataRow(label: "File", value: capture.audioFileName)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    /// Single metadata row
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
        }
    }

    // MARK: - Actions

    private func shareCapture() {
        // TODO: Implement sharing in future phase
    }

    private func archiveCapture() {
        captureStore.archiveCapture(capture)
        dismiss()
    }

    private func deleteCapture() {
        captureStore.deleteCapture(capture)
        dismiss()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Flow Layout for Tags

/// A simple flow layout that wraps content to new lines
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    CaptureDetailView(capture: Capture.samples[0])
        .environmentObject(CaptureStore.preview)
}
