//
//  CaptureStore.swift
//  Capsule
//
//  Manages the collection of captures and persists them locally.
//  In Phase 2, this will be extended to sync with Supabase.
//
//  This is the "source of truth" for all capture data in the app.
//

import Foundation
import Combine

/// Manages storage and retrieval of captures
class CaptureStore: ObservableObject {

    // MARK: - Published Properties

    /// All captures, sorted by creation date (newest first)
    @Published private(set) var captures: [Capture] = []

    /// Loading state
    @Published var isLoading = false

    /// Any error that occurred
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// File URL for persisted capture data
    private let storageURL: URL

    /// JSON encoder/decoder for persistence
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Computed Properties

    /// Captures that are not archived
    var activeCaptures: [Capture] {
        captures.filter { !$0.isArchived }
    }

    /// Captures grouped by category
    var capturesByCategory: [CaptureCategory: [Capture]] {
        Dictionary(grouping: activeCaptures) { $0.category }
    }

    /// Total recording time across all captures
    var totalDuration: TimeInterval {
        captures.reduce(0) { $0 + $1.duration }
    }

    // MARK: - Initialization

    init() {
        // Set up storage location in documents directory
        storageURL = FileManager.default.documentsDirectory
            .appendingPathComponent("captures.json")

        // Set up encoder for nice date formatting
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        // Load existing captures from disk
        loadCaptures()
    }

    // MARK: - CRUD Operations

    /// Add a new capture
    func addCapture(_ capture: Capture) {
        // Insert at beginning (newest first)
        captures.insert(capture, at: 0)
        saveCaptures()
        print("💾 Added capture: \(capture.displayTitle)")
    }

    /// Update an existing capture
    func updateCapture(_ capture: Capture) {
        if let index = captures.firstIndex(where: { $0.id == capture.id }) {
            captures[index] = capture
            saveCaptures()
            print("💾 Updated capture: \(capture.displayTitle)")
        }
    }

    /// Delete a capture (also removes the audio file)
    func deleteCapture(_ capture: Capture) {
        // Remove audio file
        let audioURL = FileManager.default.capturesDirectory
            .appendingPathComponent(capture.audioFileName)
        try? FileManager.default.removeItem(at: audioURL)

        // Remove from array
        captures.removeAll { $0.id == capture.id }
        saveCaptures()
        print("🗑️ Deleted capture: \(capture.displayTitle)")
    }

    /// Delete capture by ID
    func deleteCapture(withId id: UUID) {
        if let capture = captures.first(where: { $0.id == id }) {
            deleteCapture(capture)
        }
    }

    /// Archive a capture (soft delete)
    func archiveCapture(_ capture: Capture) {
        var updated = capture
        updated.isArchived = true
        updateCapture(updated)
        print("📦 Archived capture: \(capture.displayTitle)")
    }

    /// Unarchive a capture
    func unarchiveCapture(_ capture: Capture) {
        var updated = capture
        updated.isArchived = false
        updateCapture(updated)
    }

    /// Get a capture by ID
    func capture(withId id: UUID) -> Capture? {
        captures.first { $0.id == id }
    }

    /// Filter captures by category
    func captures(for category: CaptureCategory) -> [Capture] {
        activeCaptures.filter { $0.category == category }
    }

    /// Search captures by transcript content
    func search(query: String) -> [Capture] {
        guard !query.isEmpty else { return activeCaptures }

        let lowercaseQuery = query.lowercased()
        return activeCaptures.filter { capture in
            // Search in title
            if let title = capture.title?.lowercased(), title.contains(lowercaseQuery) {
                return true
            }
            // Search in transcript
            if let transcript = capture.transcript?.lowercased(), transcript.contains(lowercaseQuery) {
                return true
            }
            // Search in tags
            if capture.tags.contains(where: { $0.lowercased().contains(lowercaseQuery) }) {
                return true
            }
            return false
        }
    }

    // MARK: - Persistence

    /// Load captures from disk
    private func loadCaptures() {
        isLoading = true

        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            // No saved data yet, start with empty array
            isLoading = false
            print("📂 No saved captures found, starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            captures = try decoder.decode([Capture].self, from: data)
            // Sort by date (newest first)
            captures.sort { $0.createdAt > $1.createdAt }
            print("📂 Loaded \(captures.count) captures from disk")
        } catch {
            errorMessage = "Failed to load captures: \(error.localizedDescription)"
            print("❌ Error loading captures: \(error)")
        }

        isLoading = false
    }

    /// Save captures to disk
    private func saveCaptures() {
        do {
            let data = try encoder.encode(captures)
            try data.write(to: storageURL, options: .atomic)
            print("💾 Saved \(captures.count) captures to disk")
        } catch {
            errorMessage = "Failed to save captures: \(error.localizedDescription)"
            print("❌ Error saving captures: \(error)")
        }
    }

    // MARK: - Utility

    /// Clear all captures (for testing/debugging)
    func clearAllCaptures() {
        // Delete all audio files
        for capture in captures {
            let audioURL = FileManager.default.capturesDirectory
                .appendingPathComponent(capture.audioFileName)
            try? FileManager.default.removeItem(at: audioURL)
        }

        // Clear array and save
        captures = []
        saveCaptures()
        print("🧹 Cleared all captures")
    }

    /// Get storage usage in bytes
    var storageUsage: Int64 {
        let capturesDir = FileManager.default.capturesDirectory

        guard let enumerator = FileManager.default.enumerator(
            at: capturesDir,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        var totalSize: Int64 = 0
        while let fileURL = enumerator.nextObject() as? URL {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }

    /// Format storage usage as human-readable string
    var formattedStorageUsage: String {
        let bytes = storageUsage
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Preview Support

extension CaptureStore {
    /// A store pre-populated with sample data for previews
    static var preview: CaptureStore {
        let store = CaptureStore()
        store.captures = Capture.samples
        return store
    }
}
