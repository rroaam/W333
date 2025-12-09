//
//  DotMatrixView.swift
//  Capsule
//
//  The signature dot matrix visualization that gives the app its
//  hardware-device aesthetic. Responds to audio levels during recording.
//
//  Design: LED-style dots that pulse and ripple based on audio input.
//

import SwiftUI

struct DotMatrixView: View {
    /// Current audio level (0.0 to 1.0)
    let audioLevel: Float

    /// Is recording active
    let isRecording: Bool

    // Grid configuration
    private let columns = 15
    private let rows = 9
    private let dotSize: CGFloat = 6
    private let dotSpacing: CGFloat = 12

    /// Animation phase for ripple effect
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2

            Canvas { context, size in
                // Calculate grid starting position to center it
                let totalWidth = CGFloat(columns - 1) * dotSpacing
                let totalHeight = CGFloat(rows - 1) * dotSpacing
                let startX = (size.width - totalWidth) / 2
                let startY = (size.height - totalHeight) / 2

                for row in 0..<rows {
                    for col in 0..<columns {
                        let x = startX + CGFloat(col) * dotSpacing
                        let y = startY + CGFloat(row) * dotSpacing

                        // Calculate distance from center for ripple effect
                        let dx = x - centerX
                        let dy = y - centerY
                        let distance = sqrt(dx * dx + dy * dy)
                        let maxDistance = sqrt(centerX * centerX + centerY * centerY)
                        let normalizedDistance = distance / maxDistance

                        // Calculate dot opacity based on audio level and distance
                        let opacity = calculateDotOpacity(
                            distance: normalizedDistance,
                            audioLevel: CGFloat(audioLevel)
                        )

                        // Draw the dot
                        let rect = CGRect(
                            x: x - dotSize / 2,
                            y: y - dotSize / 2,
                            width: dotSize,
                            height: dotSize
                        )
                        let path = Circle().path(in: rect)

                        context.fill(
                            path,
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
            }
        }
        .onAppear {
            // Start subtle idle animation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }

    /// Calculate opacity for a dot based on distance from center and audio level
    private func calculateDotOpacity(distance: CGFloat, audioLevel: CGFloat) -> Double {
        if isRecording {
            // Active recording: dots respond to audio
            // Create ripple effect from center outward
            let ripplePosition = (animationPhase + audioLevel) * 2
            let rippleEffect = sin((distance * 3 - ripplePosition) * .pi * 2)

            // Combine audio level with ripple
            let baseOpacity = 0.15
            let audioContribution = audioLevel * 0.5
            let rippleContribution = (rippleEffect + 1) / 2 * 0.3 * audioLevel

            return min(1.0, baseOpacity + audioContribution + rippleContribution)
        } else {
            // Idle state: subtle ambient animation
            let wave = sin((distance * 2 + animationPhase * 2 * .pi)) * 0.5 + 0.5
            return 0.1 + wave * 0.1
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 40) {
            VStack {
                Text("Idle")
                    .foregroundColor(.white)
                DotMatrixView(audioLevel: 0, isRecording: false)
                    .frame(height: 150)
            }

            VStack {
                Text("Recording - Low")
                    .foregroundColor(.white)
                DotMatrixView(audioLevel: 0.3, isRecording: true)
                    .frame(height: 150)
            }

            VStack {
                Text("Recording - High")
                    .foregroundColor(.white)
                DotMatrixView(audioLevel: 0.8, isRecording: true)
                    .frame(height: 150)
            }
        }
        .padding()
    }
}
