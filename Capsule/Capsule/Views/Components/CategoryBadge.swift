//
//  CategoryBadge.swift
//  Capsule
//
//  A small badge displaying a category with its icon.
//  Used in capture cards and detail views.
//

import SwiftUI

struct CategoryBadge: View {
    let category: CaptureCategory
    let isActive: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: category.iconName)
                .font(.system(size: 10, weight: .medium))

            Text(category.displayName)
                .font(DesignSystem.Typography.caption)
        }
        .foregroundColor(isActive ? DesignSystem.Colors.background : category.color)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(isActive ? category.color : category.color.opacity(0.15))
        .cornerRadius(DesignSystem.CornerRadius.small)
        .glow(color: category.color, radius: 6, active: isActive)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 16) {
            ForEach(CaptureCategory.allCases) { category in
                HStack {
                    CategoryBadge(category: category, isActive: false)
                    CategoryBadge(category: category, isActive: true)
                }
            }
        }
    }
}
