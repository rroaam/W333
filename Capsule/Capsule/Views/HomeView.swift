//
//  HomeView.swift
//  Capsule
//
//  The main screen showing the capture feed and category selection.
//  This is where users spend most of their time browsing past captures.
//

import SwiftUI

struct HomeView: View {
    // Access the shared capture store
    @EnvironmentObject var captureStore: CaptureStore

    // Callback when user taps a category to start recording
    let onCategorySelected: (CaptureCategory) -> Void

    // MARK: - State

    /// Currently selected filter category (nil = show all)
    @State private var selectedFilter: CaptureCategory?

    /// Search query text
    @State private var searchQuery = ""

    /// Currently selected capture for detail view
    @State private var selectedCapture: Capture?

    /// Show detail sheet
    @State private var showingDetail = false

    // MARK: - Computed Properties

    /// Filtered list of captures based on category and search
    private var filteredCaptures: [Capture] {
        var result = captureStore.activeCaptures

        // Apply category filter
        if let category = selectedFilter {
            result = result.filter { $0.category == category }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            result = captureStore.search(query: searchQuery)
            if let category = selectedFilter {
                result = result.filter { $0.category == category }
            }
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with logo/title
            headerView

            // Category buttons for recording
            CategorySelectionBar(onCategorySelected: onCategorySelected)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)

            // Divider
            Rectangle()
                .fill(DesignSystem.Colors.stroke)
                .frame(height: 1)

            // Filter chips
            filterChipsView
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)

            // Capture feed
            if filteredCaptures.isEmpty {
                emptyStateView
            } else {
                captureListView
            }
        }
        .background(DesignSystem.Colors.background)
        .sheet(isPresented: $showingDetail) {
            if let capture = selectedCapture {
                CaptureDetailView(capture: capture)
                    .environmentObject(captureStore)
            }
        }
    }

    // MARK: - Subviews

    /// App header with title
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CAPSULE")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .tracking(2)  // Letter spacing for that hardware feel

                Text("\(captureStore.activeCaptures.count) captures")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.mutedText)
            }

            Spacer()

            // Settings button (placeholder for now)
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(DesignSystem.Colors.mutedText)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }

    /// Category filter chips
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // "All" chip
                FilterChip(
                    title: "ALL",
                    isSelected: selectedFilter == nil,
                    color: .white
                ) {
                    selectedFilter = nil
                }

                // Category chips
                ForEach(CaptureCategory.allCases) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: selectedFilter == category,
                        color: category.color
                    ) {
                        selectedFilter = selectedFilter == category ? nil : category
                    }
                }
            }
        }
    }

    /// Empty state when no captures match
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()

            Image(systemName: "waveform")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(DesignSystem.Colors.mutedText)

            Text(selectedFilter != nil ? "No \(selectedFilter!.displayName.lowercased()) captures yet" : "No captures yet")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.mutedText)

            Text("Tap a category above to start recording")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText.opacity(0.6))

            Spacer()
        }
    }

    /// List of capture cards
    private var captureListView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(filteredCaptures) { capture in
                    CaptureCard(capture: capture)
                        .onTapGesture {
                            selectedCapture = capture
                            showingDetail = true
                        }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - Filter Chip Component

/// A tappable chip for filtering by category
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(isSelected ? DesignSystem.Colors.background : color)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(isSelected ? color : Color.clear)
                .cornerRadius(DesignSystem.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(onCategorySelected: { _ in })
        .environmentObject(CaptureStore.preview)
}
