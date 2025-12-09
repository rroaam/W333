//
//  RecordingView.swift
//  Capsule
//
//  Full-screen recording interface shown when user starts a capture.
//  Features the dot matrix aesthetic with live timer and audio visualization.
//

import SwiftUI

struct RecordingView: View {
    // The category user selected
    let category: CaptureCategory

    // Callbacks for when recording completes or is cancelled
    let onComplete: (Capture?) -> Void
    let onCancel: () -> Void

    // MARK: - State

    @StateObject private var recorder = AudioRecorder()

    /// Current recording filename
    @State private var currentFilename: String?

    /// Recording state machine
    @State private var recordingState: RecordingState = .preparing

    /// Animation state for pulsing effect
    @State private var isPulsing = false

    /// Haptic feedback generator
    private let haptics = UIImpactFeedbackGenerator(style: .medium)

    enum RecordingState {
        case preparing   // Getting permissions, setting up
        case recording   // Actively recording
        case saving      // Brief saving animation
        case error       // Something went wrong
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.xl) {
                // Top: Category indicator
                categoryHeader

                Spacer()

                // Center: Timer and visualization
                centerContent

                Spacer()

                // Bottom: Controls
                controlsSection
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .onAppear {
            startRecording()
        }
        .onDisappear {
            // Clean up if view disappears unexpectedly
            if recorder.isRecording {
                recorder.cancelRecording()
            }
        }
    }

    // MARK: - Subviews

    /// Category badge at top
    private var categoryHeader: some View {
        HStack {
            CategoryBadge(category: category, isActive: true)
            Spacer()

            // Cancel button
            Button(action: cancelRecording) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.mutedText)
                    .frame(width: 36, height: 36)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(18)
            }
        }
    }

    /// Center content with timer and visualization
    private var centerContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Dot matrix visualization area
            DotMatrixView(
                audioLevel: recorder.audioLevel,
                isRecording: recordingState == .recording
            )
            .frame(height: 200)

            // Timer display
            timerDisplay

            // State label
            stateLabel
        }
    }

    /// Large timer display
    private var timerDisplay: some View {
        Text(recorder.currentDuration.formatted)
            .font(DesignSystem.Typography.timer)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .monospacedDigit()
            .glow(color: category.color, radius: recordingState == .recording ? 12 : 0)
            .animation(.easeInOut(duration: 0.3), value: recordingState)
    }

    /// State indicator label
    private var stateLabel: some View {
        Group {
            switch recordingState {
            case .preparing:
                Text("PREPARING...")
                    .foregroundColor(DesignSystem.Colors.mutedText)
            case .recording:
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(isPulsing ? 1 : 0.3)
                    Text("RECORDING")
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            case .saving:
                Text("SAVING...")
                    .foregroundColor(category.color)
            case .error:
                Text(recorder.errorMessage ?? "ERROR")
                    .foregroundColor(.red)
            }
        }
        .font(DesignSystem.Typography.caption)
        .tracking(2)
        .onAppear {
            // Start pulsing animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    /// Bottom controls
    private var controlsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Main stop button
            stopButton

            // Hint text
            Text("Tap to stop recording")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText)
        }
    }

    /// Large stop button
    private var stopButton: some View {
        Button(action: stopRecording) {
            ZStack {
                // Outer ring with glow
                Circle()
                    .stroke(category.color.opacity(0.3), lineWidth: 2)
                    .frame(width: 88, height: 88)
                    .glow(color: category.color, radius: 16, active: recordingState == .recording)

                // Inner stop icon (rounded square)
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.primaryText)
                    .frame(width: 32, height: 32)
            }
        }
        .disabled(recordingState != .recording)
    }

    // MARK: - Actions

    /// Start the recording process
    private func startRecording() {
        Task {
            // Request microphone permission
            let hasPermission = await recorder.requestPermission()

            guard hasPermission else {
                recordingState = .error
                return
            }

            // Start recording
            DispatchQueue.main.async {
                if let filename = recorder.startRecording() {
                    currentFilename = filename
                    recordingState = .recording
                    haptics.impactOccurred()
                } else {
                    recordingState = .error
                }
            }
        }
    }

    /// Stop recording and save
    private func stopRecording() {
        guard recordingState == .recording else { return }

        haptics.impactOccurred()
        recordingState = .saving

        let duration = recorder.stopRecording()

        // Create the capture object
        if let filename = currentFilename, duration > 0.5 {
            let capture = Capture(
                category: category,
                audioFileName: filename,
                duration: duration
            )

            // Brief delay for saving animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete(capture)
            }
        } else {
            // Recording too short, discard
            if let filename = currentFilename {
                recorder.deleteRecording(filename: filename)
            }
            onComplete(nil)
        }
    }

    /// Cancel recording without saving
    private func cancelRecording() {
        haptics.impactOccurred(intensity: 0.5)
        recorder.cancelRecording()
        onCancel()
    }
}

// MARK: - Preview

#Preview {
    RecordingView(
        category: .idea,
        onComplete: { _ in },
        onCancel: {}
    )
}
