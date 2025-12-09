//
//  SoundManager.swift
//  Capsule
//
//  Manages all sound effects in the app.
//  Uses system sounds for reliability, with option for custom sounds later.
//
//  Sound Philosophy: Short, distinct sounds that reinforce actions.
//  Sounds should be satisfying but not annoying on repeat.
//

import AVFoundation
import AudioToolbox

/// Singleton manager for all sound effects in the app
final class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    /// Audio player for custom sounds
    private var audioPlayer: AVAudioPlayer?

    /// Whether sounds are enabled (user preference)
    var soundsEnabled: Bool = true

    /// Volume for sound effects (0.0 to 1.0)
    var volume: Float = 0.8

    // MARK: - System Sound IDs
    // These are built-in iOS system sounds that work reliably

    private enum SystemSound: UInt32 {
        // Keyboard/UI sounds
        case tock = 1104           // Soft tick
        case tick = 1105           // Sharp tick

        // Alerts
        case alert = 1007          // SMS received type sound
        case tweet = 1016          // Short chirp

        // Camera
        case shutter = 1108        // Camera shutter

        // Lock
        case lock = 1100           // Lock sound
        case unlock = 1101         // Unlock sound

        // Payment
        case payment = 1407        // Payment success

        // Key press variations
        case keyPress1 = 1123
        case keyPress2 = 1124
        case keyPress3 = 1125

        // Mail
        case mailSent = 1001       // Swoosh

        // Modern iOS sounds
        case beginRecord = 1113    // Begin recording
        case endRecord = 1114      // End recording
        case shake = 1109          // Shake gesture
    }

    // MARK: - Initialization

    private init() {
        // Configure audio session to allow sounds during recording
        configureAudioSession()
    }

    private func configureAudioSession() {
        // Audio session is configured in AudioRecorder
        // This is just for standalone sound playback
    }

    // MARK: - Core Sound Methods

    /// Play a system sound by ID
    private func playSystemSound(_ sound: SystemSound) {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(sound.rawValue)
    }

    /// Play a system sound with optional vibration
    private func playAlertSound(_ sound: SystemSound) {
        guard soundsEnabled else { return }
        AudioServicesPlayAlertSound(sound.rawValue)
    }

    // MARK: - App-Specific Sounds

    /// Sound when tapping a category button to start recording
    func playCategoryTap() {
        playSystemSound(.tick)
    }

    /// Sound when recording begins - distinctive "start" sound
    func playRecordingStart() {
        playSystemSound(.beginRecord)
    }

    /// Sound when recording stops
    func playRecordingStop() {
        playSystemSound(.endRecord)
    }

    /// Sound when recording is saved successfully
    func playRecordingSaved() {
        playSystemSound(.payment)
    }

    /// Sound when recording is cancelled
    func playRecordingCancelled() {
        playSystemSound(.tock)
    }

    /// Warning sound when approaching time limit
    func playTimeWarning() {
        // Double beep for attention
        playSystemSound(.tick)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            playSystemSound(.tick)
        }
    }

    /// Sound when max duration is reached
    func playMaxDurationReached() {
        playAlertSound(.alert)
    }

    /// Sound when starting playback
    func playPlaybackStart() {
        playSystemSound(.tock)
    }

    /// Sound when pausing playback
    func playPlaybackPause() {
        playSystemSound(.tock)
    }

    /// Sound for skip forward/backward
    func playSkip() {
        playSystemSound(.tick)
    }

    /// Sound when deleting a capture
    func playDelete() {
        playSystemSound(.shake)
    }

    /// Sound when archiving
    func playArchive() {
        playSystemSound(.mailSent)
    }

    /// Sound for general button tap
    func playButtonTap() {
        playSystemSound(.tick)
    }

    /// Sound for filter/chip selection
    func playFilterTap() {
        playSystemSound(.tock)
    }

    /// Sound for card tap (opening detail)
    func playCardTap() {
        playSystemSound(.keyPress1)
    }

    /// Sound for success actions
    func playSuccess() {
        playSystemSound(.payment)
    }

    /// Sound for errors
    func playError() {
        playAlertSound(.alert)
    }

    // MARK: - Countdown Sounds

    /// Tick sound for countdown timer (last 10 seconds)
    func playCountdownTick() {
        playSystemSound(.tick)
    }

    /// Final countdown sound (last 3 seconds)
    func playFinalCountdown() {
        playAlertSound(.tick)
    }

    // MARK: - Custom Sound Playback

    /// Play a custom sound file from the bundle
    /// - Parameter name: The filename without extension
    /// - Parameter ext: The file extension (default: "wav")
    func playCustomSound(named name: String, extension ext: String = "wav") {
        guard soundsEnabled else { return }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Sound file not found: \(name).\(ext)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    // MARK: - Convenience Combinations

    /// Combined haptic + sound for recording start
    func feedbackRecordingStart() {
        playRecordingStart()
        HapticManager.shared.recordingStarted()
    }

    /// Combined haptic + sound for recording stop
    func feedbackRecordingStop() {
        playRecordingStop()
        HapticManager.shared.recordingStopped()
    }

    /// Combined haptic + sound for recording saved
    func feedbackRecordingSaved() {
        playRecordingSaved()
        HapticManager.shared.recordingSaved()
    }

    /// Combined haptic + sound for category selection
    func feedbackCategoryTap() {
        playCategoryTap()
        HapticManager.shared.categoryTap()
    }

    /// Combined haptic + sound for time warning
    func feedbackTimeWarning() {
        playTimeWarning()
        HapticManager.shared.timeWarning()
    }

    /// Combined haptic + sound for max duration
    func feedbackMaxDuration() {
        playMaxDurationReached()
        HapticManager.shared.maxDurationReached()
    }

    /// Combined haptic + sound for delete
    func feedbackDelete() {
        playDelete()
        HapticManager.shared.delete()
    }
}
