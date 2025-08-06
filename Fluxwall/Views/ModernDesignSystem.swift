import SwiftUI

// MARK: - 现代化设计系统
// 轻量级设计系统，提供统一的视觉样式

struct ModernDesignSystem {
    
    // MARK: - 颜色系统
    struct Colors {
        // 扁平化淡色背景 - 简洁温和
        static let cardBackground = Color(red: 0.94, green: 0.94, blue: 0.95, opacity: 0.06)
        static let cardBackgroundActive = Color(red: 0.96, green: 0.96, blue: 0.97, opacity: 0.09)
        
        // 圆润边框色系 - 重点在边框设计
        static let softBorder = Color(red: 0.88, green: 0.88, blue: 0.90, opacity: 0.12)
        static let softBorderActive = Color(red: 0.82, green: 0.82, blue: 0.85, opacity: 0.18)
        static let accentBorder = Color(red: 0.60, green: 0.80, blue: 1.0, opacity: 0.3)
        
        // 极简阴影 - 仅用于轻微分层
        static let subtleShadow = Color.black.opacity(0.08)
        static let lightShadow = Color.black.opacity( 0.12)
        
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
        
        // 去除高光效果 - 保持扁平化
        // 移除了复杂的高光和内阴影系统
    }
    
    // MARK: - 圆润边框系统
    struct CornerRadius {
        static let small: CGFloat = 8      // 更圆润的小圆角
        static let medium: CGFloat = 12     // 中等圆润度
        static let large: CGFloat = 16      // 大圆角，更现代
        static let extraLarge: CGFloat = 20 // 超大圆角，用于特殊组件
    }
    
    // MARK: - 极简阴影系统
    struct Shadow {
        // 极轻阴影 - 仅用于分层
        static let minimal = ShadowStyle(
            color: Colors.subtleShadow,
            radius: 2,
            offset: CGSize(width: 0, height: 1)
        )
        
        // 轻微阴影 - 用于交互状态
        static let light = ShadowStyle(
            color: Colors.lightShadow,
            radius: 4,
            offset: CGSize(width: 0, height: 2)
        )
        
        // 无阴影 - 完全扁平
        static let none = ShadowStyle(
            color: Color.clear,
            radius: 0,
            offset: CGSize.zero
        )
    }
    
    // MARK: - 间距系统
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
}

// MARK: - 阴影样式结构
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let offset: CGSize
}

// MARK: - 扁平化圆润卡片样式
struct FlatCardStyle: ViewModifier {
    let isActive: Bool
    let cornerRadius: CGFloat
    let shadowStyle: ShadowStyle
    let borderIntensity: Double
    
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
                // 简洁的扁平背景
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        isActive ? 
                        ModernDesignSystem.Colors.cardBackgroundActive : 
                        ModernDesignSystem.Colors.cardBackground
                    )
            )
            .overlay(
                // 圆润的边框 - 设计重点
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isActive ? 
                        ModernDesignSystem.Colors.softBorderActive : 
                        ModernDesignSystem.Colors.softBorder,
                        lineWidth: isActive ? 1.5 : 1.0
                    )
                    .opacity(borderIntensity)
            )
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.offset.width,
                y: shadowStyle.offset.height
            )
    }
}

// MARK: - 扁平化圆润按钮样式
struct FlatButtonStyle: ButtonStyle {
    let isSelected: Bool
    let cornerRadius: CGFloat
    let borderIntensity: Double
    
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .modifier(
                FlatCardStyle(
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

struct AnimatedToggleButtonStyle: ButtonStyle {
    let isSelected: Bool
    let cornerRadius: CGFloat
    
    init(isSelected: Bool, cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
                                ModernDesignSystem.Colors.cardBackground,
                                ModernDesignSystem.Colors.cardBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isSelected ? 
                            ModernDesignSystem.Colors.gradientBlueStart.opacity(0.4) : 
                            ModernDesignSystem.Colors.subtleShadow,
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected ? 
                            ModernDesignSystem.Colors.gradientBlueStart.opacity(0.6) : 
                            ModernDesignSystem.Colors.softBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func titleGradient() -> some View {
        self.foregroundStyle(ModernDesignSystem.Colors.titleGradient)
    }
    
    func animatedToggleButton(isSelected: Bool, cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium) -> some View {
        self.buttonStyle(AnimatedToggleButtonStyle(isSelected: isSelected, cornerRadius: cornerRadius))
    }
    
    func flatCard(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal,
        borderIntensity: Double = 1.0
    ) -> some View {
        self.modifier(
            FlatCardStyle(
                isActive: isActive,
                cornerRadius: cornerRadius,
                shadowStyle: shadowStyle,
                borderIntensity: borderIntensity
            )
        )
    }
    
    func flatButton(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.small,
        borderIntensity: Double = 1.0
    ) -> some View {
        self.buttonStyle(
            FlatButtonStyle(
                isSelected: isSelected,
                cornerRadius: cornerRadius,
                borderIntensity: borderIntensity
            )
        )
    }
    
    // 向后兼容方法 - 映射到新的扁平化设计
    func glassCard(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal,
        glassIntensity: Double = 1.0
    ) -> some View {
        self.flatCard(
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
        self.flatButton(
            isSelected: isSelected,
            cornerRadius: cornerRadius,
            borderIntensity: glassIntensity
        )
    }
    
    // 兼容性方法
    func modernCard(
        isActive: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
        shadowStyle: ShadowStyle = ModernDesignSystem.Shadow.minimal
    ) -> some View {
        self.flatCard(
            isActive: isActive,
            cornerRadius: cornerRadius,
            shadowStyle: shadowStyle
        )
    }
    
    func modernButton(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.small
    ) -> some View {
        self.flatButton(
            isSelected: isSelected,
            cornerRadius: cornerRadius
        )
    }
}