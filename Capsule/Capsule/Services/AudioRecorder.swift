//
//  AudioRecorder.swift
//  Capsule
//
//  Handles all audio recording functionality using AVFoundation.
//  This service manages the microphone, recording state, and file output.
//
//  Key Concepts for a Coding Newcomer:
//  - AVAudioRecorder: Apple's class for recording audio to a file
//  - AVAudioSession: Manages your app's audio behavior (we need permission!)
//  - @Published: Makes properties observable so SwiftUI updates automatically
//  - ObservableObject: Allows this class to work with SwiftUI's state system
//

import Foundation
import AVFoundation
import Combine

/// Manages audio recording for voice captures
class AudioRecorder: NSObject, ObservableObject {

    // MARK: - Published Properties (SwiftUI will react to these changes)

    /// Is the recorder currently recording?
    @Published var isRecording = false

    /// Current recording duration in seconds (updates every 0.1s while recording)
    @Published var currentDuration: TimeInterval = 0

    /// Audio levels for visualization (0.0 to 1.0)
    @Published var audioLevel: Float = 0

    /// Any error that occurred during recording
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// The actual audio recorder from AVFoundation
    private var audioRecorder: AVAudioRecorder?

    /// Timer to update duration and audio levels during recording
    private var timer: Timer?

    /// The file URL where we're currently recording to
    private var currentRecordingURL: URL?

    /// When recording started (for calculating duration)
    private var recordingStartTime: Date?

    // MARK: - Audio Settings

    /// Audio format settings optimized for voice recording
    /// These settings balance quality with file size
    private let audioSettings: [String: Any] = [
        // AAC is great for voice - good quality, small files
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),

        // 44.1kHz is CD quality - plenty for voice
        AVSampleRateKey: 44100.0,

        // Mono is fine for voice (stereo would double file size)
        AVNumberOfChannelsKey: 1,

        // High quality encoding
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,

        // Good bitrate for voice clarity
        AVEncoderBitRateKey: 128000
    ]

    // MARK: - Public Methods

    /// Request microphone permission from the user
    /// Call this before attempting to record
    func requestPermission() async -> Bool {
        // Check current authorization status
        let status = AVAudioApplication.shared.recordPermission

        switch status {
        case .granted:
            return true

        case .denied:
            errorMessage = "Microphone access denied. Please enable in Settings."
            return false

        case .undetermined:
            // Ask the user for permission
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if !granted {
                            self.errorMessage = "Microphone access is required to record."
                        }
                        continuation.resume(returning: granted)
                    }
                }
            }

        @unknown default:
            return false
        }
    }

    /// Start recording audio
    /// Returns the filename being recorded to (for creating the Capture later)
    @discardableResult
    func startRecording() -> String? {
        // Don't start if already recording
        guard !isRecording else {
            errorMessage = "Already recording"
            return nil
        }

        // Reset error state
        errorMessage = nil

        // Configure audio session for recording
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
            return nil
        }

        // Generate unique filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "capture_\(timestamp).m4a"
        let fileURL = FileManager.default.capturesDirectory.appendingPathComponent(filename)

        // Create and configure the recorder
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true  // Enable audio level metering
            audioRecorder?.prepareToRecord()

            guard audioRecorder?.record() == true else {
                errorMessage = "Failed to start recording"
                return nil
            }

            // Update state
            currentRecordingURL = fileURL
            recordingStartTime = Date()
            isRecording = true
            currentDuration = 0

            // Start timer to update duration and audio levels
            startTimer()

            print("📍 Recording started: \(filename)")
            return filename

        } catch {
            errorMessage = "Failed to create recorder: \(error.localizedDescription)"
            return nil
        }
    }

    /// Stop the current recording
    /// Returns the duration of the recording
    func stopRecording() -> TimeInterval {
        guard isRecording, let recorder = audioRecorder else {
            return 0
        }

        // Stop the recorder
        recorder.stop()

        // Calculate final duration
        let duration = recorder.currentTime

        // Clean up
        stopTimer()
        isRecording = false
        audioLevel = 0

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)

        print("📍 Recording stopped. Duration: \(String(format: "%.1f", duration))s")

        return duration
    }

    /// Cancel the current recording and delete the file
    func cancelRecording() {
        guard isRecording else { return }

        // Stop recording
        audioRecorder?.stop()
        stopTimer()

        // Delete the partial recording file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
            print("📍 Recording cancelled and deleted")
        }

        // Reset state
        isRecording = false
        currentDuration = 0
        audioLevel = 0
        currentRecordingURL = nil
    }

    /// Delete a recording file
    func deleteRecording(filename: String) {
        let fileURL = FileManager.default.capturesDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
        print("📍 Deleted recording: \(filename)")
    }

    // MARK: - Private Methods

    /// Start the timer that updates duration and audio levels
    private func startTimer() {
        // Update every 0.1 seconds for smooth UI updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, self.isRecording else { return }

            // Update duration
            self.currentDuration = recorder.currentTime

            // Update audio levels for visualization
            recorder.updateMeters()
            // Convert decibels to 0-1 range (meters return -160 to 0 dB)
            let db = recorder.averagePower(forChannel: 0)
            let normalizedLevel = max(0, (db + 50) / 50)  // Map -50dB...0dB to 0...1
            self.audioLevel = normalizedLevel
        }
    }

    /// Stop the update timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    /// Called when recording finishes (either normally or due to an error)
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            if !flag {
                self.errorMessage = "Recording did not complete successfully"
            }
            self.isRecording = false
        }
    }

    /// Called if recording is interrupted (phone call, etc.)
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.errorMessage = error?.localizedDescription ?? "Encoding error occurred"
            self.isRecording = false
        }
    }
}

// MARK: - Duration Formatting Extension

extension TimeInterval {
    /// Format as MM:SS string (e.g., "01:45")
    var formatted: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Format as M:SS string for shorter display (e.g., "1:45")
    var shortFormatted: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
