import SwiftUI

// MARK: - UIColor Extension

extension UIColor {
    convenience init?(hex: String) {
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
            return nil
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Color Extension

extension Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Theme Palette

enum ThemePalette: String, CaseIterable, Identifiable {
    case violet = "Violet"
    case teal = "Teal"
    case coral = "Coral"
    case forest = "Forest"
    case amber = "Amber"
    
    var id: String { rawValue }
    
    var accent: Color {
        switch self {
        case .violet: return Color(hex: "#5b4fcf")
        case .teal: return Color(hex: "#0d9488")
        case .coral: return Color(hex: "#e85a4f")
        case .forest: return Color(hex: "#2d6a4f")
        case .amber: return Color(hex: "#d4862a")
        }
    }
    
    var accentLight: Color {
        switch self {
        case .violet: return Color(hex: "#ede9ff")
        case .teal: return Color(hex: "#ccfbf1")
        case .coral: return Color(hex: "#fee2e0")
        case .forest: return Color(hex: "#d8f3dc")
        case .amber: return Color(hex: "#fdf0e0")
        }
    }
    
    var accentMid: Color {
        switch self {
        case .violet: return Color(hex: "#9b92e8")
        case .teal: return Color(hex: "#5eead4")
        case .coral: return Color(hex: "#f4a29a")
        case .forest: return Color(hex: "#74c69d")
        case .amber: return Color(hex: "#e8b86d")
        }
    }
}

// MARK: - Design System

enum DesignSystem {
    // MARK: - Theme
    
    static var currentTheme: ThemePalette = .violet
    
    // MARK: - Dynamic Accent (Theme-aware)
    
    static var accent: Color { currentTheme.accent }
    static var accentLight: Color { currentTheme.accentLight }
    static var accentMid: Color { currentTheme.accentMid }
    
    // MARK: - Adaptive Colors (Dark Mode Support)
    
    // Ink scale - adaptive for dark mode
    static let ink = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#F5F5F7") ?? .label
            : UIColor(hex: "#1a1714") ?? .label
    })
    static let ink2 = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#D1D1D6") ?? .secondaryLabel
            : UIColor(hex: "#4a453f") ?? .secondaryLabel
    })
    static let ink3 = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#A1A1A6") ?? .tertiaryLabel
            : UIColor(hex: "#8a837a") ?? .tertiaryLabel
    })
    static let ink4 = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#6E6E73") ?? .separator
            : UIColor(hex: "#c4bdb6") ?? .separator
    })
    
    // Parchment scale (backgrounds) - adaptive for dark mode
    static let parchment = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#1C1C1E") ?? .systemBackground
            : UIColor(hex: "#f7f3ee") ?? .systemBackground
    })
    static let parchment2 = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#2C2C2E") ?? .secondarySystemBackground
            : UIColor(hex: "#ede7de") ?? .secondarySystemBackground
    })
    static let parchment3 = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#3A3A3C") ?? .tertiarySystemBackground
            : UIColor(hex: "#e2d9ce") ?? .tertiarySystemBackground
    })
    
    // Card background - adaptive
    static let card = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#2C2C2E") ?? .secondarySystemBackground
            : UIColor.white
    })
    
    // Primary accent (violet - kept for backward compatibility)
    static var violet: Color { accent }
    static var violetLight: Color { accentLight }
    static var violetMid: Color { accentMid }
    
    // Semantic colors - adaptive for dark mode
    static let amber = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#F5A623") ?? .systemOrange
            : UIColor(hex: "#d4862a") ?? .systemOrange
    })
    static let amberLight = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#3D2E1A") ?? .secondarySystemBackground
            : UIColor(hex: "#fdf0e0") ?? .secondarySystemBackground
    })
    
    static let green = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#4ADE80") ?? .systemGreen
            : UIColor(hex: "#3a7d5c") ?? .systemGreen
    })
    static let greenLight = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#1A3D2A") ?? .secondarySystemBackground
            : UIColor(hex: "#e8f5ef") ?? .secondarySystemBackground
    })
    
    static let red = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#F87171") ?? .systemRed
            : UIColor(hex: "#c0392b") ?? .systemRed
    })
    static let redLight = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#3D1A1A") ?? .secondarySystemBackground
            : UIColor(hex: "#fdecea") ?? .secondarySystemBackground
    })
    
    // Screen tint colors for evaluation feedback
    static let greenTint = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#1A3D2A") ?? .systemBackground
            : UIColor(hex: "#f0faf5") ?? .systemBackground
    })
    static let redTint = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#3D1A1A") ?? .systemBackground
            : UIColor(hex: "#fef5f4") ?? .systemBackground
    })
    
    // Evaluation drawer colors
    static let greenMid = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#7ABFA0") ?? .systemGreen
            : UIColor(hex: "#7abfa0") ?? .systemGreen
    })
    static let redMid = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#E8928C") ?? .systemRed
            : UIColor(hex: "#e8928c") ?? .systemRed
    })
    
    // MARK: - Typography
    
    /// Lora serif font - for titles and quotes
    static func serif(size: CGFloat) -> Font {
        .custom("Lora", size: size)
    }
    
    /// DM Sans - for UI elements
    static func sans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("DM Sans", size: size).weight(weight)
    }
    
    // MARK: - Radii
    
    static let radius: CGFloat = 14
    static let radiusSm: CGFloat = 8
    
    // MARK: - Spacing
    
    static let spacingXS: CGFloat = 4
    static let spacingSm: CGFloat = 8
    static let spacingMd: CGFloat = 12
    static let spacingLg: CGFloat = 16
    static let spacingXl: CGFloat = 24
    
    // MARK: - Animation
    
    static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    static let springSnappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
    static let springGentle = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    
    // MARK: - Haptics
    
    struct Haptics {
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        static func medium() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        static func success() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // MARK: - Component Styles
    
    /// Standard button style for primary actions
    static func primaryButton() -> some ButtonStyle {
        PrimaryButtonStyle()
    }
    
    /// Chip selector style
    static func chip(selected: Bool, color: Color = violet) -> some View {
        Text("")
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? violetLight : card)
            .foregroundColor(selected ? violet : ink2)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selected ? violetMid : parchment3, lineWidth: 1)
            )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("DM Sans", size: 15).weight(.medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(DesignSystem.violet)
            .cornerRadius(DesignSystem.radius)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply parchment background
    func parchmentBackground() -> some View {
        self.background(DesignSystem.parchment)
    }
    
    /// Card style with border
    func cardStyle() -> some View {
        self
            .background(DesignSystem.card)
            .cornerRadius(DesignSystem.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.radiusSm)
                    .stroke(DesignSystem.parchment3, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Color swatches
        HStack {
            Circle().fill(DesignSystem.ink).frame(width: 40, height: 40)
            Circle().fill(DesignSystem.violet).frame(width: 40, height: 40)
            Circle().fill(DesignSystem.amber).frame(width: 40, height: 40)
            Circle().fill(DesignSystem.green).frame(width: 40, height: 40)
        }
        
        // Typography
        Text("Serif Title").font(DesignSystem.serif(size: 22))
        Text("Sans UI Text").font(DesignSystem.sans(size: 14))
        
        // Chip example
        HStack {
            Text("Selected").modifier(ChipModifier(selected: true))
            Text("Unselected").modifier(ChipModifier(selected: false))
        }
        
        // Button
        Button("Continue →") {}
            .buttonStyle(PrimaryButtonStyle())
    }
    .padding()
    .background(DesignSystem.parchment)
}

// MARK: - Chip Modifier

struct ChipModifier: ViewModifier {
    let selected: Bool
    var color: Color = DesignSystem.violet
    
    func body(content: Content) -> some View {
        content
            .font(.custom("DM Sans", size: 12).weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? DesignSystem.violetLight : DesignSystem.card)
            .foregroundColor(selected ? DesignSystem.violet : DesignSystem.ink2)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selected ? DesignSystem.violetMid : DesignSystem.parchment3, lineWidth: 1)
            )
    }
}

extension View {
    func chip(selected: Bool, color: Color = DesignSystem.violet) -> some View {
        modifier(ChipModifier(selected: selected, color: color))
    }
}
