import SwiftUI

struct ModernDesignSystem {
    
    struct Colors {
        static func cardBackground(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color(red: 0.94, green: 0.94, blue: 0.95, opacity: 0.06)
            case .light:
                return Color(.controlBackgroundColor).opacity(0.8)
            @unknown default:
                return Color(red: 0.94, green: 0.94, blue: 0.95, opacity: 0.06)
            }
        }
        
        static func cardBackgroundActive(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color(red: 0.96, green: 0.96, blue: 0.97, opacity: 0.09)
            case .light:
                return Color(.controlBackgroundColor).opacity(0.95)
            @unknown default:
                return Color(red: 0.96, green: 0.96, blue: 0.97, opacity: 0.09)
            }
        }
        
        static func softBorder(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color(red: 0.88, green: 0.88, blue: 0.90, opacity: 0.12)
            case .light:
                return Color(.separatorColor).opacity(0.3)
            @unknown default:
                return Color(red: 0.88, green: 0.88, blue: 0.90, opacity: 0.12)
            }
        }
        
        static func softBorderActive(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color(red: 0.82, green: 0.82, blue: 0.85, opacity: 0.18)
            case .light:
                return Color(.separatorColor).opacity(0.5)
            @unknown default:
                return Color(red: 0.82, green: 0.82, blue: 0.85, opacity: 0.18)
            }
        }
        
        static func subtleShadow(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color.black.opacity(0.08)
            case .light:
                return Color(.shadowColor).opacity(0.1)
            @unknown default:
                return Color.black.opacity(0.08)
            }
        }
        
        static func lightShadow(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color.black.opacity(0.12)
            case .light:
                return Color(.shadowColor).opacity(0.15)
            @unknown default:
                return Color.black.opacity(0.12)
            }
        }
        
        static func appBackground(for colorScheme: ColorScheme) -> LinearGradient {
            switch colorScheme {
            case .dark:
                return LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .light:
                return LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.98, blue: 0.99),
                        Color(red: 0.95, green: 0.96, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            @unknown default:
                return LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        static let primaryText = Color(.labelColor)
        static let secondaryText = Color(.secondaryLabelColor)
        static let tertiaryText = Color(.tertiaryLabelColor)
        
        static let successColor = Color(.systemGreen)
        static let warningColor = Color(.systemOrange)
        static let errorColor = Color(.systemRed)
        static let infoColor = Color(.systemBlue)
        
        static let gradientBlueStart = Color(red: 0.3, green: 0.7, blue: 1.0)
        static let gradientBlueMid = Color(red: 0.1, green: 0.5, blue: 0.9)
        static let gradientPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
        static let gradientGreen = Color(red: 0.2, green: 0.8, blue: 0.6)
        static let gradientBlueEnd = Color(red: 0.0, green: 0.3, blue: 0.7)
        
        static let titleGradient = LinearGradient(
            colors: [
                gradientBlueStart,
                gradientBlueMid,
                gradientPurple,
                gradientGreen,
                gradientBlueEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentBorder = Color.accentColor.opacity(0.6)
        static let buttonBackground = Color(.controlColor)
        static let buttonBackgroundActive = Color(.controlAccentColor)
        static let buttonText = Color(.controlTextColor)
        static let buttonTextActive = Color(.alternateSelectedControlTextColor)
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8      
        static let medium: CGFloat = 12   
        static let large: CGFloat = 16     
        static let extraLarge: CGFloat = 20
    }
    
    struct Shadow {
        static let minimal = ShadowStyle(
            color: Colors.subtleShadow,
            radius: 2,
            offset: CGSize(width: 0, height: 1)
        )
        
        static let light = ShadowStyle(
            color: Colors.lightShadow,
            radius: 4,
            offset: CGSize(width: 0, height: 2)
        )
        
        static let medium = ShadowStyle(
            color: Colors.lightShadow,
            radius: 8,
            offset: CGSize(width: 0, height: 4)
        )
        
        static let none = ShadowStyle(
            color: Color.clear,
            radius: 0,
            offset: CGSize.zero
        )
    }
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let offset: CGSize
}

struct AdaptiveCardStyle: ViewModifier {
    let isActive: Bool
    let cornerRadius: CGFloat
    let shadowStyle: ShadowStyle
    let borderIntensity: Double
    @Environment(\.colorScheme) var colorScheme
    
    init(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal,
        borderIntensity: Double = 1.0
    ) {
        self.isActive = isActive
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
        self.borderIntensity = borderIntensity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        isActive ? 
                        ModernDesignSystem.Colors.cardBackgroundActive(for: colorScheme) : 
                        ModernDesignSystem.Colors.cardBackground(for: colorScheme)
                    )
                    .background(
                        colorScheme == .light ?
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial) : nil
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isActive ? 
                        ModernDesignSystem.Colors.softBorderActive(for: colorScheme) : 
                        ModernDesignSystem.Colors.softBorder(for: colorScheme),
                        lineWidth: isActive ? 1.5 : 1.0
                    )
                    .opacity(borderIntensity)
            )
            .shadow(
                color: ModernDesignSystem.Colors.subtleShadow(for: colorScheme),
                radius: shadowStyle.radius,
                x: shadowStyle.offset.width,
                y: shadowStyle.offset.height
            )
    }
}

struct AdaptiveButtonStyle: ButtonStyle {
    let isSelected: Bool
    let cornerRadius: CGFloat
    let borderIntensity: Double
    @Environment(\.colorScheme) var colorScheme
    
    init(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.small,
        borderIntensity: Double = 1.0
    ) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
        self.borderIntensity = borderIntensity
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(
                isSelected || configuration.isPressed ? 
                ModernDesignSystem.Colors.buttonTextActive : 
                ModernDesignSystem.Colors.primaryText
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .modifier(
                AdaptiveCardStyle(
                    isActive: isSelected || configuration.isPressed,
                    cornerRadius: cornerRadius,
                    shadowStyle: configuration.isPressed ? 
                        ModernDesignSystem.Shadow.none : 
                        ModernDesignSystem.Shadow.minimal,
                    borderIntensity: configuration.isPressed ? borderIntensity * 1.2 : borderIntensity
                )
            )
    }
}

struct DragDropCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        colorScheme == .light ?
                        Color(.controlBackgroundColor).opacity(0.3) :
                        Color(red: 0.94, green: 0.94, blue: 0.95, opacity: 0.06)
                    )
                    .background(
                        colorScheme == .light ?
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial) : nil
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .light ?
                        Color(.separatorColor).opacity(0.2) :
                        Color(red: 0.88, green: 0.88, blue: 0.90, opacity: 0.12),
                        lineWidth: 1.0
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                ModernDesignSystem.Colors.infoColor.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
            )
            .shadow(
                color: ModernDesignSystem.Colors.subtleShadow(for: colorScheme),
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

struct AnimatedToggleButtonStyle: ButtonStyle {
    let isSelected: Bool
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    init(isSelected: Bool, cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(
                isSelected ? 
                ModernDesignSystem.Colors.buttonTextActive : 
                ModernDesignSystem.Colors.primaryText
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isSelected ? 1.05 : 1.0))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            colors: [
                                ModernDesignSystem.Colors.gradientBlueStart,
                                ModernDesignSystem.Colors.gradientBlueMid
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                ModernDesignSystem.Colors.cardBackground(for: colorScheme),
                                ModernDesignSystem.Colors.cardBackground(for: colorScheme)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        colorScheme == .light && !isSelected ?
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial) : nil
                    )
                    .shadow(
                        color: isSelected ? 
                            ModernDesignSystem.Colors.gradientBlueStart.opacity(0.4) : 
                            ModernDesignSystem.Colors.subtleShadow(for: colorScheme),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected ? 
                            ModernDesignSystem.Colors.accentBorder : 
                            ModernDesignSystem.Colors.softBorder(for: colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func titleGradient() -> some View {
        self.foregroundStyle(ModernDesignSystem.Colors.titleGradient)
    }
    
    func dragDropCard(cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large) -> some View {
        self.modifier(DragDropCardStyle(cornerRadius: cornerRadius))
    }
    
    func animatedToggleButton(isSelected: Bool, cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium) -> some View {
        self.buttonStyle(AnimatedToggleButtonStyle(isSelected: isSelected, cornerRadius: cornerRadius))
    }
    
    func adaptiveCard(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal,
        borderIntensity: Double = 1.0
    ) -> some View {
        self.modifier(
            AdaptiveCardStyle(
                isActive: isActive,
                cornerRadius: cornerRadius,
                shadowStyle: shadowStyle,
                borderIntensity: borderIntensity
            )
        )
    }
    
    func adaptiveButton(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.small,
        borderIntensity: Double = 1.0
    ) -> some View {
        self.buttonStyle(
            AdaptiveButtonStyle(
                isSelected: isSelected,
                cornerRadius: cornerRadius,
                borderIntensity: borderIntensity
            )
        )
    }
    
    func flatCard(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal,
        borderIntensity: Double = 1.0
    ) -> some View {
        self.adaptiveCard(
            isActive: isActive,
            cornerRadius: cornerRadius,
            shadowStyle: shadowStyle,
            borderIntensity: borderIntensity
        )
    }
    
    func flatButton(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.small,
        borderIntensity: Double = 1.0
    ) -> some View {
        self.adaptiveButton(
            isSelected: isSelected,
            cornerRadius: cornerRadius,
            borderIntensity: borderIntensity
        )
    }
    
    func glassCard(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal,
        glassIntensity: Double = 1.0
    ) -> some View {
        self.adaptiveCard(
            isActive: isActive,
            cornerRadius: cornerRadius,
            shadowStyle: shadowStyle,
            borderIntensity: glassIntensity
        )
    }
    
    func glassButton(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.small,
        glassIntensity: Double = 1.0
    ) -> some View {
        self.adaptiveButton(
            isSelected: isSelected,
            cornerRadius: cornerRadius,
            borderIntensity: glassIntensity
        )
    }
    
    func modernCard(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal
    ) -> some View {
        self.adaptiveCard(
            isActive: isActive,
            cornerRadius: cornerRadius,
            shadowStyle: shadowStyle
        )
    }
    
    func modernButton(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.small
    ) -> some View {
        self.adaptiveButton(
            isSelected: isSelected,
            cornerRadius: cornerRadius
        )
    }
}