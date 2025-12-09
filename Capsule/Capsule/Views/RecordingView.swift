//
//  RecordingView.swift
//  Capsule
//
//  Full-screen recording interface shown when user starts a capture.
//  Features the dot matrix aesthetic with live timer and audio visualization.
//  Includes 3-minute max recording limit with warnings.
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

    /// Whether we're in the warning zone (last 30 seconds)
    @State private var isInWarningZone = false

    /// Countdown for last 10 seconds
    @State private var countdownTimer: Timer?

    /// Last second we played a tick for
    @State private var lastTickSecond: Int = -1

    enum RecordingState {
        case preparing   // Getting permissions, setting up
        case recording   // Actively recording
        case saving      // Brief saving animation
        case error       // Something went wrong
    }

    // MARK: - Computed Properties

    /// Time remaining until max duration
    private var timeRemaining: TimeInterval {
        max(0, AudioRecorder.maxDuration - recorder.currentDuration)
    }

    /// Formatted time remaining (for display in warning zone)
    private var timeRemainingFormatted: String {
        let seconds = Int(timeRemaining)
        return "\(seconds)s"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - changes color in warning zone
            backgroundView
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
            setupRecorderCallbacks()
            startRecording()
        }
        .onDisappear {
            // Clean up if view disappears unexpectedly
            countdownTimer?.invalidate()
            if recorder.isRecording {
                recorder.cancelRecording()
            }
        }
        .onChange(of: recorder.currentDuration) { _, newDuration in
            // Play countdown ticks in last 10 seconds
            handleCountdownTicks(duration: newDuration)
        }
    }

    // MARK: - Subviews

    /// Background that pulses red in warning zone
    private var backgroundView: some View {
        ZStack {
            DesignSystem.Colors.background

            // Red overlay for warning zone
            if isInWarningZone {
                Color.red
                    .opacity(isPulsing ? 0.15 : 0.05)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPulsing)
            }
        }
    }

    /// Category badge at top
    private var categoryHeader: some View {
        HStack {
            CategoryBadge(category: category, isActive: true)

            Spacer()

            // Time remaining indicator (in warning zone)
            if isInWarningZone && recordingState == .recording {
                Text(timeRemainingFormatted)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.red)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(DesignSystem.CornerRadius.small)
            }

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

            // Max duration indicator
            maxDurationIndicator

            // State label
            stateLabel
        }
    }

    /// Large timer display
    private var timerDisplay: some View {
        Text(recorder.currentDuration.formatted)
            .font(DesignSystem.Typography.timer)
            .foregroundColor(isInWarningZone ? .red : DesignSystem.Colors.primaryText)
            .monospacedDigit()
            .glow(color: isInWarningZone ? .red : category.color, radius: recordingState == .recording ? 12 : 0)
            .animation(.easeInOut(duration: 0.3), value: recordingState)
            .animation(.easeInOut(duration: 0.3), value: isInWarningZone)
    }

    /// Shows max duration limit
    private var maxDurationIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.stroke)
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isInWarningZone ? Color.red : category.color)
                        .frame(width: geometry.size.width * (recorder.currentDuration / AudioRecorder.maxDuration), height: 4)
                        .animation(.linear(duration: 0.1), value: recorder.currentDuration)
                }
            }
            .frame(height: 4)

            // Max label
            Text("3:00")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText)
                .monospacedDigit()
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
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
                        .fill(isInWarningZone ? Color.red : Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(isPulsing ? 1 : 0.3)

                    if isInWarningZone {
                        Text("TIME RUNNING OUT")
                            .foregroundColor(.red)
                    } else {
                        Text("RECORDING")
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
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
            Text(isInWarningZone ? "Recording will auto-stop at 3:00" : "Tap to stop recording")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(isInWarningZone ? .red.opacity(0.7) : DesignSystem.Colors.mutedText)
        }
    }

    /// Large stop button
    private var stopButton: some View {
        Button(action: stopRecording) {
            ZStack {
                // Outer ring with glow
                Circle()
                    .stroke((isInWarningZone ? Color.red : category.color).opacity(0.3), lineWidth: 2)
                    .frame(width: 88, height: 88)
                    .glow(color: isInWarningZone ? .red : category.color, radius: 16, active: recordingState == .recording)

                // Inner stop icon (rounded square)
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.primaryText)
                    .frame(width: 32, height: 32)
            }
        }
        .disabled(recordingState != .recording)
    }

    // MARK: - Setup

    /// Set up callbacks for recorder events
    private func setupRecorderCallbacks() {
        // Warning when approaching limit
        recorder.onApproachingLimit = { [self] in
            isInWarningZone = true
            SoundManager.shared.feedbackTimeWarning()
        }

        // Auto-stop when max duration reached
        recorder.onMaxDurationReached = { [self] in
            SoundManager.shared.feedbackMaxDuration()
            // Auto-stop the recording
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                stopRecording()
            }
        }
    }

    // MARK: - Countdown

    /// Handle countdown ticks in the last 10 seconds
    private func handleCountdownTicks(duration: TimeInterval) {
        let remaining = AudioRecorder.maxDuration - duration
        let currentSecond = Int(remaining)

        // Only tick in last 10 seconds, and only once per second
        if remaining <= 10 && remaining > 0 && currentSecond != lastTickSecond {
            lastTickSecond = currentSecond

            if remaining <= 3 {
                // Final countdown - more intense
                SoundManager.shared.playFinalCountdown()
                HapticManager.shared.heavyTap()
            } else {
                // Regular countdown tick
                SoundManager.shared.playCountdownTick()
                HapticManager.shared.lightTap()
            }
        }
    }

    // MARK: - Actions

    /// Start the recording process
    private func startRecording() {
        Task {
            // Request microphone permission
            let hasPermission = await recorder.requestPermission()

            guard hasPermission else {
                recordingState = .error
                SoundManager.shared.playError()
                HapticManager.shared.error()
                return
            }

            // Start recording
            DispatchQueue.main.async {
                if let filename = recorder.startRecording() {
                    currentFilename = filename
                    recordingState = .recording

                    // Heavy feedback for recording start
                    SoundManager.shared.feedbackRecordingStart()
                } else {
                    recordingState = .error
                    SoundManager.shared.playError()
                    HapticManager.shared.error()
                }
            }
        }
    }

    /// Stop recording and save
    private func stopRecording() {
        guard recordingState == .recording else { return }

        // Feedback for stop
        SoundManager.shared.feedbackRecordingStop()

        recordingState = .saving

        let duration = recorder.stopRecording()

        // Create the capture object
        if let filename = currentFilename, duration > 0.5 {
            let capture = Capture(
                category: category,
                audioFileName: filename,
                duration: duration
            )

            // Brief delay for saving animation, then success feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                SoundManager.shared.feedbackRecordingSaved()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onComplete(capture)
            }
        } else {
            // Recording too short, discard
            if let filename = currentFilename {
                recorder.deleteRecording(filename: filename)
            }
            HapticManager.shared.warning()
            onComplete(nil)
        }
    }

    /// Cancel recording without saving
    private func cancelRecording() {
        SoundManager.shared.playRecordingCancelled()
        HapticManager.shared.recordingCancelled()
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
