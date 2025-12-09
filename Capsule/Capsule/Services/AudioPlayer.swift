//
//  AudioPlayer.swift
//  Capsule
//
//  Handles audio playback for recorded captures.
//  Provides playback controls and progress tracking for the UI.
//

import Foundation
import AVFoundation
import Combine

/// Manages audio playback for captures
class AudioPlayer: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Is audio currently playing?
    @Published var isPlaying = false

    /// Current playback position in seconds
    @Published var currentTime: TimeInterval = 0

    /// Total duration of the audio
    @Published var duration: TimeInterval = 0

    /// Playback progress (0.0 to 1.0)
    @Published var progress: Double = 0

    /// Any error that occurred during playback
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// The AVAudioPlayer instance
    private var audioPlayer: AVAudioPlayer?

    /// Timer for updating playback position
    private var timer: Timer?

    /// The file currently loaded (to avoid reloading)
    private var currentFile: String?

    // MARK: - Public Methods

    /// Load an audio file for playback
    func load(filename: String) {
        // Don't reload if already loaded
        guard filename != currentFile else { return }

        stop()

        let fileURL = FileManager.default.capturesDirectory.appendingPathComponent(filename)

        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            errorMessage = "Audio file not found"
            return
        }

        do {
            // Configure audio session for playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            // Create player
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // Update state
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            progress = 0
            currentFile = filename
            errorMessage = nil

        } catch {
            errorMessage = "Failed to load audio: \(error.localizedDescription)"
        }
    }

    /// Start or resume playback
    func play() {
        guard let player = audioPlayer else {
            errorMessage = "No audio loaded"
            return
        }

        player.play()
        isPlaying = true
        startTimer()
    }

    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    /// Toggle between play and pause
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Stop playback and reset to beginning
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        progress = 0
        stopTimer()
    }

    /// Seek to a specific position (0.0 to 1.0)
    func seek(to position: Double) {
        guard let player = audioPlayer else { return }

        let time = position * duration
        player.currentTime = time
        currentTime = time
        progress = position
    }

    /// Skip forward by a number of seconds
    func skipForward(seconds: TimeInterval = 10) {
        guard let player = audioPlayer else { return }

        let newTime = min(player.currentTime + seconds, duration)
        player.currentTime = newTime
        updateProgress()
    }

    /// Skip backward by a number of seconds
    func skipBackward(seconds: TimeInterval = 10) {
        guard let player = audioPlayer else { return }

        let newTime = max(player.currentTime - seconds, 0)
        player.currentTime = newTime
        updateProgress()
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        progress = duration > 0 ? currentTime / duration : 0
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.stopTimer()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.errorMessage = error?.localizedDescription ?? "Playback error"
            self.isPlaying = false
            self.stopTimer()
        }
    }
}
