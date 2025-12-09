//
//  DesignSystem.swift
//  Capsule
//
//  Central design system defining all visual constants.
//  This ensures consistency across the app and makes future tweaks easy.
//
//  Design Philosophy: Hardware-device aesthetic. Like a dedicated voice
//  recorder from the future. Flat, confident, minimal — not another software app.
//

import SwiftUI

/// Namespace for all design system constants
enum DesignSystem {

    // MARK: - Colors

    /// Color palette matching the design spec
    enum Colors {
        /// Primary background: near-black (#111111)
        static let background = Color(hex: "111111")

        /// Slightly lighter surface for cards (#1A1A1A)
        static let surface = Color(hex: "1A1A1A")

        /// Container stroke color (#333333)
        static let stroke = Color(hex: "333333")

        /// Primary text: pure white
        static let primaryText = Color.white

        /// Muted text and icons (#666666)
        static let mutedText = Color(hex: "666666")

        /// Active/recording state indicator
        static let active = Color.white

        /// Category-specific colors (subtle tints for distinction)
        static let idea = Color(hex: "FFE066")      // Warm yellow
        static let vision = Color(hex: "66D9FF")    // Cool cyan
        static let reflect = Color(hex: "66FF99")   // Fresh green
        static let plans = Color(hex: "FF8566")     // Warm coral
    }

    // MARK: - Typography

    /// Typography styles using pixel/monospace fonts
    enum Typography {
        /// Primary display font - pixel style for that hardware feel
        /// Falls back through: Silkscreen → Chicago → Departure Mono → SF Mono
        static func displayFont(size: CGFloat) -> Font {
            // Try custom fonts first, fall back to SF Mono
            .custom("Silkscreen-Regular", size: size, relativeTo: .body)
        }

        /// Monospace font for timestamps, technical text
        static func monoFont(size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }

        /// Body text font
        static func bodyFont(size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }

        // Predefined text styles
        static let largeTitle = monoFont(size: 32)
        static let title = monoFont(size: 24)
        static let headline = monoFont(size: 18)
        static let body = bodyFont(size: 16)
        static let caption = monoFont(size: 12)
        static let timer = monoFont(size: 48)
    }

    // MARK: - Spacing

    /// Consistent spacing values (4pt grid system)
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    /// Corner radius values for rounded square containers
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
    }

    // MARK: - Animation

    /// Standard animation timings
    enum Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        /// Pulse animation for recording state
        static let pulse = SwiftUI.Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    }

    // MARK: - Shadows & Effects

    /// Glow effect for active states
    static func glowEffect(color: Color = .white, radius: CGFloat = 8) -> some View {
        color.opacity(0.3).blur(radius: radius)
    }
}

// MARK: - Color Hex Extension

extension Color {
    /// Initialize a Color from a hex string (e.g., "FF0000" for red)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the standard card style: dark surface, stroke border, rounded corners
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
            )
    }

    /// Apply a subtle glow effect (for active/recording states)
    func glow(color: Color = .white, radius: CGFloat = 8, active: Bool = true) -> some View {
        self.shadow(color: active ? color.opacity(0.4) : .clear, radius: radius)
    }
}
