//
//  CapsuleApp.swift
//  Capsule
//
//  The main entry point for the Capsule voice capture app.
//  This file sets up the app's root view and initializes core services.
//

import SwiftUI

@main
struct CapsuleApp: App {
    // StateObject keeps our data store alive for the entire app lifecycle
    @StateObject private var captureStore = CaptureStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the store into the environment so all views can access it
                .environmentObject(captureStore)
                // Apply our dark theme globally
                .preferredColorScheme(.dark)
        }
    }
}
