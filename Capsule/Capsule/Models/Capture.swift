//
//  Capture.swift
//  Capsule
//
//  Core data model representing a voice capture.
//  Designed to be compatible with future Supabase integration (Phase 2).
//

import Foundation

/// Represents a single voice capture recording
struct Capture: Identifiable, Codable, Equatable {
    /// Unique identifier for this capture
    let id: UUID

    /// User who created this capture (for future multi-user support)
    let userId: String

    /// The category selected at time of recording
    /// This is the "intent" - user picks category, AI enhances later
    var category: CaptureCategory

    /// Local file path to the audio recording
    /// In Phase 2, this becomes a Supabase Storage URL
    let audioFileName: String

    /// AI-generated transcript of the audio (nil until processed)
    var transcript: String?

    /// AI-generated title from transcript (5-8 words max)
    var title: String?

    /// AI-extracted keyword tags
    var tags: [String]

    /// Duration of the recording in seconds
    let duration: TimeInterval

    /// When this capture was created
    let createdAt: Date

    /// Whether this capture has been archived
    var isArchived: Bool

    // MARK: - Initialization

    /// Create a new capture with required fields
    init(
        id: UUID = UUID(),
        userId: String = "local",  // Default for Phase 1 (no auth)
        category: CaptureCategory,
        audioFileName: String,
        transcript: String? = nil,
        title: String? = nil,
        tags: [String] = [],
        duration: TimeInterval,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.category = category
        self.audioFileName = audioFileName
        self.transcript = transcript
        self.title = title
        self.tags = tags
        self.duration = duration
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    // MARK: - Computed Properties

    /// Full path to the audio file in the app's documents directory
    var audioURL: URL {
        FileManager.default.documentsDirectory.appendingPathComponent(audioFileName)
    }

    /// Display title: use AI title if available, otherwise a default
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return "Untitled \(category.displayName)"
    }

    /// Formatted duration string (MM:SS)
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Relative time string (e.g., "2h ago", "Yesterday")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Preview of transcript (first ~50 characters)
    var transcriptPreview: String? {
        guard let transcript = transcript, !transcript.isEmpty else { return nil }
        if transcript.count <= 60 {
            return transcript
        }
        return String(transcript.prefix(60)) + "..."
    }
}

// MARK: - CaptureCategory

/// The four capture categories - user picks intent at recording time
enum CaptureCategory: String, Codable, CaseIterable, Identifiable {
    case idea = "IDEA"
    case vision = "VISION"
    case reflect = "REFLECT"
    case plans = "PLANS"

    var id: String { rawValue }

    /// Human-readable display name
    var displayName: String { rawValue }

    /// SF Symbol name for this category's icon
    /// Using thin stroke icons as per design spec
    var iconName: String {
        switch self {
        case .idea: return "lightbulb"           // Lightbulb for ideas
        case .vision: return "rectangle.on.rectangle"  // Frames for vision
        case .reflect: return "checkmark.square" // Checkbox for reflection
        case .plans: return "calendar"           // Calendar for plans
        }
    }

    /// Category-specific accent color
    var color: SwiftUI.Color {
        switch self {
        case .idea: return DesignSystem.Colors.idea
        case .vision: return DesignSystem.Colors.vision
        case .reflect: return DesignSystem.Colors.reflect
        case .plans: return DesignSystem.Colors.plans
        }
    }
}

// MARK: - FileManager Extension

extension FileManager {
    /// App's documents directory for storing audio files
    var documentsDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Directory specifically for Capsule audio recordings
    var capturesDirectory: URL {
        let directory = documentsDirectory.appendingPathComponent("Captures", isDirectory: true)
        // Create directory if it doesn't exist
        if !fileExists(atPath: directory.path) {
            try? createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}

// MARK: - Sample Data (for previews and testing)

extension Capture {
    /// Sample captures for SwiftUI previews
    static let samples: [Capture] = [
        Capture(
            category: .idea,
            audioFileName: "sample1.m4a",
            transcript: "What if we added a feature that lets users share their captures as audio postcards? They could add a custom background and send them to friends.",
            title: "Audio Postcards Feature",
            tags: ["feature", "sharing", "social"],
            duration: 45,
            createdAt: Date().addingTimeInterval(-3600)  // 1 hour ago
        ),
        Capture(
            category: .vision,
            audioFileName: "sample2.m4a",
            transcript: "I'm imagining the app in five years. It's become the default way people capture fleeting thoughts. The widget is iconic.",
            title: "Five Year Vision",
            tags: ["vision", "growth", "product"],
            duration: 120,
            createdAt: Date().addingTimeInterval(-86400)  // Yesterday
        ),
        Capture(
            category: .reflect,
            audioFileName: "sample3.m4a",
            transcript: "Today I realized that most of my best ideas come during walks. I should make walking a daily habit.",
            title: "Walking and Ideas",
            tags: ["habits", "creativity", "reflection"],
            duration: 30,
            createdAt: Date().addingTimeInterval(-172800)  // 2 days ago
        ),
        Capture(
            category: .plans,
            audioFileName: "sample4.m4a",
            transcript: "This week I need to finish the prototype, set up the backend, and schedule user testing sessions.",
            title: "Weekly Sprint Goals",
            tags: ["planning", "sprint", "tasks"],
            duration: 25,
            createdAt: Date().addingTimeInterval(-259200)  // 3 days ago
        )
    ]
}
