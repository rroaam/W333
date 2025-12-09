//
//  WaveformView.swift
//  Capsule
//
//  A minimal waveform visualization for audio playback.
//  Shows playback progress with a simple bar visualization.
//

import SwiftUI

struct WaveformView: View {
    /// Playback progress (0.0 to 1.0)
    let progress: Double

    /// Number of bars in the waveform
    private let barCount = 50

    /// Random heights for bars (generated once)
    @State private var barHeights: [CGFloat] = []

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(barCount) * 0.7
            let barSpacing = geometry.size.width / CGFloat(barCount) * 0.3

            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    let normalizedIndex = CGFloat(index) / CGFloat(barCount)
                    let isPastProgress = normalizedIndex <= progress

                    // Get height for this bar
                    let height = barHeights.indices.contains(index)
                        ? barHeights[index]
                        : 0.5

                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(isPastProgress
                            ? DesignSystem.Colors.primaryText
                            : DesignSystem.Colors.mutedText.opacity(0.3))
                        .frame(width: barWidth, height: geometry.size.height * height)
                }
            }
            .frame(height: geometry.size.height, alignment: .center)
        }
        .onAppear {
            generateBarHeights()
        }
    }

    /// Generate random-looking but deterministic bar heights
    private func generateBarHeights() {
        barHeights = (0..<barCount).map { index in
            // Create a pseudo-waveform pattern
            let base = 0.3
            let variation = sin(Double(index) * 0.5) * 0.2
            let noise = sin(Double(index) * 1.7) * 0.15
            let peak = index > barCount / 3 && index < barCount * 2 / 3 ? 0.2 : 0

            return CGFloat(min(1.0, max(0.2, base + variation + noise + peak)))
        }
    }
}

// MARK: - Alternative: Simpler Progress Bar

/// A simple progress bar alternative to the waveform
struct SimpleProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.mutedText.opacity(0.2))
                    .frame(height: 4)

                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.primaryText)
                    .frame(width: geometry.size.width * progress, height: 4)

                // Playhead dot
                Circle()
                    .fill(DesignSystem.Colors.primaryText)
                    .frame(width: 12, height: 12)
                    .offset(x: geometry.size.width * progress - 6)
            }
            .frame(height: geometry.size.height)
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
                Text("0%")
                    .foregroundColor(.white)
                WaveformView(progress: 0)
                    .frame(height: 60)
            }

            VStack {
                Text("50%")
                    .foregroundColor(.white)
                WaveformView(progress: 0.5)
                    .frame(height: 60)
            }

            VStack {
                Text("100%")
                    .foregroundColor(.white)
                WaveformView(progress: 1.0)
                    .frame(height: 60)
            }

            Divider()

            VStack {
                Text("Simple Progress")
                    .foregroundColor(.white)
                SimpleProgressBar(progress: 0.6)
                    .frame(height: 20)
            }
        }
        .padding()
    }
}
