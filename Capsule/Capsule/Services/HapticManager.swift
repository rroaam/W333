//
//  HapticManager.swift
//  Capsule
//
//  Centralized haptic feedback manager for the entire app.
//  Uses heavy, satisfying haptics to reinforce the hardware-device aesthetic.
//
//  Haptic Philosophy: Every important interaction should FEEL substantial.
//  This isn't a soft, floaty app — it's a precision instrument.
//

import UIKit
import CoreHaptics

/// Singleton manager for all haptic feedback in the app
final class HapticManager {

    // MARK: - Singleton

    /// Shared instance for app-wide access
    static let shared = HapticManager()

    // MARK: - Haptic Engines

    /// Impact feedback generators (pre-warmed for instant response)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)

    /// Selection feedback for discrete choices
    private let selection = UISelectionFeedbackGenerator()

    /// Notification feedback for outcomes
    private let notification = UINotificationFeedbackGenerator()

    /// Core Haptics engine for custom patterns
    private var engine: CHHapticEngine?

    /// Whether Core Haptics is available on this device
    private var supportsHaptics: Bool = false

    // MARK: - Initialization

    private init() {
        // Pre-warm all generators for instant response
        prepareGenerators()

        // Set up Core Haptics if available
        setupCoreHaptics()
    }

    /// Pre-warm haptic generators so they're ready instantly
    private func prepareGenerators() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        softImpact.prepare()
        selection.prepare()
        notification.prepare()
    }

    /// Initialize Core Haptics engine for custom patterns
    private func setupCoreHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }

        supportsHaptics = true

        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true

            // Auto-restart if engine stops
            engine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                self?.restartEngine()
            }

            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                try? self?.engine?.start()
            }

            try engine?.start()
        } catch {
            print("Failed to create haptic engine: \(error)")
            supportsHaptics = false
        }
    }

    private func restartEngine() {
        guard supportsHaptics else { return }
        try? engine?.start()
    }

    // MARK: - Simple Haptics

    /// Light tap - for minor UI feedback
    func lightTap() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Medium tap - for standard button presses
    func mediumTap() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Heavy tap - for important actions
    func heavyTap() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }

    /// Rigid impact - sharp, precise feedback (like a physical button click)
    func rigidTap() {
        rigidImpact.impactOccurred()
        rigidImpact.prepare()
    }

    /// Soft impact - cushioned feedback
    func softTap() {
        softImpact.impactOccurred()
        softImpact.prepare()
    }

    /// Selection tick - for scrolling through options
    func selectionTick() {
        selection.selectionChanged()
        selection.prepare()
    }

    // MARK: - Notification Haptics

    /// Success feedback - task completed
    func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// Warning feedback - attention needed
    func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    /// Error feedback - something went wrong
    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    // MARK: - Custom App-Specific Haptics

    /// Category button tap - satisfying click when selecting a category
    func categoryTap() {
        // Double impact for extra weight
        rigidImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            heavyImpact.impactOccurred(intensity: 0.7)
            heavyImpact.prepare()
        }
        rigidImpact.prepare()
    }

    /// Recording started - strong confirmation that recording has begun
    func recordingStarted() {
        // Heavy double-tap pattern
        heavyImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            rigidImpact.impactOccurred(intensity: 1.0)
            rigidImpact.prepare()
        }
        heavyImpact.prepare()
    }

    /// Recording stopped - definitive end to recording
    func recordingStopped() {
        // Sharp stop feedback
        rigidImpact.impactOccurred(intensity: 1.0)
        rigidImpact.prepare()
    }

    /// Recording saved - satisfying confirmation
    func recordingSaved() {
        // Success with extra oomph
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            mediumImpact.impactOccurred(intensity: 0.6)
            mediumImpact.prepare()
        }
        notification.prepare()
    }

    /// Recording cancelled - quick dismissive feedback
    func recordingCancelled() {
        softImpact.impactOccurred(intensity: 0.8)
        softImpact.prepare()
    }

    /// Time warning - approaching max duration (30 seconds left)
    func timeWarning() {
        // Attention-getting pattern
        warning()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            mediumImpact.impactOccurred(intensity: 0.5)
            mediumImpact.prepare()
        }
    }

    /// Max duration reached - recording auto-stopped
    func maxDurationReached() {
        // Strong warning that something happened
        notification.notificationOccurred(.warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            heavyImpact.impactOccurred(intensity: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            rigidImpact.impactOccurred(intensity: 0.8)
            rigidImpact.prepare()
        }
        heavyImpact.prepare()
        notification.prepare()
    }

    /// Playback started
    func playbackStarted() {
        mediumImpact.impactOccurred(intensity: 0.7)
        mediumImpact.prepare()
    }

    /// Playback paused
    func playbackPaused() {
        softImpact.impactOccurred(intensity: 0.6)
        softImpact.prepare()
    }

    /// Skip forward/backward
    func skip() {
        lightImpact.impactOccurred(intensity: 0.8)
        lightImpact.prepare()
    }

    /// Delete action - destructive feedback
    func delete() {
        // Heavy, definitive
        heavyImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            rigidImpact.impactOccurred(intensity: 0.9)
            rigidImpact.prepare()
        }
        heavyImpact.prepare()
    }

    /// Card tap - opening a capture detail
    func cardTap() {
        mediumImpact.impactOccurred(intensity: 0.6)
        mediumImpact.prepare()
    }

    /// Filter chip tap
    func filterTap() {
        lightImpact.impactOccurred(intensity: 0.8)
        lightImpact.prepare()
    }

    // MARK: - Core Haptics Patterns

    /// Play a custom "pulse" pattern - used during recording
    func recordingPulse(intensity: Float) {
        guard supportsHaptics, let engine = engine else {
            // Fallback to basic haptic
            if intensity > 0.5 {
                lightImpact.impactOccurred(intensity: CGFloat(intensity * 0.3))
            }
            return
        }

        do {
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.4)

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [sharpness, intensityParam],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Fallback silently
        }
    }

    /// Play the "saved" celebration pattern
    func celebrateSave() {
        guard supportsHaptics, let engine = engine else {
            // Fallback
            success()
            return
        }

        do {
            var events: [CHHapticEvent] = []

            // Rising intensity pattern
            for i in 0..<4 {
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(i + 1) * 0.25
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: Float(i) * 0.2
                )

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: TimeInterval(i) * 0.08
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Fallback
            success()
        }
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Add heavy haptic feedback to any tap gesture
    func hapticTap(_ style: HapticStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .light: HapticManager.shared.lightTap()
                case .medium: HapticManager.shared.mediumTap()
                case .heavy: HapticManager.shared.heavyTap()
                case .rigid: HapticManager.shared.rigidTap()
                case .category: HapticManager.shared.categoryTap()
                }
            }
        )
    }
}

/// Haptic feedback styles for the view extension
enum HapticStyle {
    case light
    case medium
    case heavy
    case rigid
    case category
}
