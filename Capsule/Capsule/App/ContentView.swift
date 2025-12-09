//
//  ContentView.swift
//  Capsule
//
//  The root view that manages navigation between main app sections.
//  Uses a simple state machine to switch between home and recording modes.
//

import SwiftUI

struct ContentView: View {
    // Access the shared capture store from environment
    @EnvironmentObject var captureStore: CaptureStore

    // Track which view we're currently showing
    @State private var isRecording = false
    @State private var selectedCategory: CaptureCategory?

    var body: some View {
        ZStack {
            // Background: near-black as per design spec
            DesignSystem.Colors.background
                .ignoresSafeArea()

            // Main content switches based on recording state
            if isRecording, let category = selectedCategory {
                // Recording mode: full-screen recording interface
                RecordingView(
                    category: category,
                    onComplete: { capture in
                        // When recording completes, save it and return to home
                        if let capture = capture {
                            captureStore.addCapture(capture)
                        }
                        isRecording = false
                        selectedCategory = nil
                    },
                    onCancel: {
                        isRecording = false
                        selectedCategory = nil
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Home mode: shows capture feed with category buttons
                HomeView(
                    onCategorySelected: { category in
                        selectedCategory = category
                        isRecording = true
                    }
                )
                .transition(.opacity)
            }
        }
        // Smooth animation between states
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }
}

#Preview {
    ContentView()
        .environmentObject(CaptureStore())
}
