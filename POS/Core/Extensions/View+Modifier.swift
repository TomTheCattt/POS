//
//  View+Modifier.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - View Extensions

extension View {
    func dismissKeyboardOnTap() -> some View {
        self
            .background(Color.clear.contentShape(Rectangle()))
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    func applyNavigationStyle(_ style: NavigationStyle) -> some View {
        self
            .transition(style.transition)
            .animation(style.animation, value: true)
    }
    
    func applyBackgroundEffect(_ effect: BackgroundEffect) -> some View {
        self
            .background(
                Group {
                    if effect.opacity > 0 {
                        Color.black.opacity(effect.opacity)
                            .edgesIgnoringSafeArea(.all)
                    }
                    if effect.blurRadius > 0 {
                        BlurView(style: .systemThinMaterial)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            )
    }
}

extension View {
    func overlayStyle(
        config: NavigationConfig = .default,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(OverlayModifier(
            config: config,
            onDismiss: onDismiss
        ))
    }
}

extension View {
    func keyboardResponsive() -> some View {
        self.modifier(KeyboardResponsiveModifier())
    }
}

extension View {
    func layeredBackground(
        tabThemeColors: TabThemeColor,
        level: LayerLevel,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        self.modifier(LayeredBackground(
            tabThemeColors: tabThemeColors,
            level: level,
            cornerRadius: cornerRadius
        ))
    }
    
    // Convenience methods for each layer
    func backgroundLayer(tabThemeColors: TabThemeColor, cornerRadius: CGFloat? = nil) -> some View {
        self.layeredBackground(tabThemeColors: tabThemeColors, level: .first, cornerRadius: cornerRadius)
    }
    
    func middleLayer(tabThemeColors: TabThemeColor, cornerRadius: CGFloat? = nil) -> some View {
        self.layeredBackground(tabThemeColors: tabThemeColors, level: .second, cornerRadius: cornerRadius)
    }
    
    func topLayer(tabThemeColors: TabThemeColor, cornerRadius: CGFloat? = nil) -> some View {
        self.layeredBackground(tabThemeColors: tabThemeColors, level: .third, cornerRadius: cornerRadius)
    }
}

extension View {
    func layeredCard(
        tabThemeColors: TabThemeColor,
        level: LayerLevel = .second,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        self.modifier(LayeredCard(tabThemeColors: tabThemeColors, level: level, cornerRadius: cornerRadius))
    }
    
    func layeredButton(
        tabThemeColors: TabThemeColor,
        level: LayerLevel = .third,
        cornerRadius: CGFloat? = nil,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(LayeredButton(tabThemeColors: tabThemeColors, level: level, cornerRadius: cornerRadius, action: action))
    }
    
    func layeredAlertButton(
        cornerRadius: CGFloat? = nil,
        hasStroke: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(LayeredAlertButton(cornerRadius: cornerRadius, hasStroke: hasStroke, action: action))
    }
    
    func layeredSelectionButton(
        tabThemeColors: TabThemeColor,
        level: LayerLevel = .first,
        cornerRadius: CGFloat? = nil,
        isCapsule: Bool = false,
        isSelected: Bool,
        namespace: Namespace.ID,
        geometryID: String,
        action: @escaping () -> Void
    ) -> some View {
        modifier(LayeredSelectionButton(
            tabThemeColors: tabThemeColors,
            level: level,
            cornerRadius: cornerRadius,
            isCapsule: isCapsule,
            isSelected: isSelected,
            namespace: namespace,
            geometryID: geometryID,
            action: action
        ))
    }
}

extension View {
    func layeredTextField(
        tabThemeColors: TabThemeColor,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        self.modifier(LayeredTextFieldBackground(tabThemeColors: tabThemeColors, cornerRadius: cornerRadius))
    }
}

extension View {
    func layeredFocusField(
        themeColors: TabThemeColor,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        field: AppTextField,
        focusField: FocusState<AppTextField?>.Binding
    ) -> some View {
        self.modifier(LayeredFocusTextField(themeColors: themeColors, keyboardType: keyboardType, textContentType: textContentType, field: field, focusField: focusField))
    }
}

// MARK: - View Modifier

struct ShakeEffect: ViewModifier {
    @Binding var shake: Bool
    @State private var animationAmount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? animationAmount : 0)
            .onChange(of: shake) { newValue in
                if newValue {
                    withAnimation(
                        Animation
                            .easeInOut(duration: 0.1)
                            .repeatCount(5, autoreverses: true)
                    ) {
                        animationAmount = -10
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.1)) {
                        animationAmount = 0
                    }
                }
            }
    }
}

struct PressEventModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                onPress()
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in onRelease() }
            )
    }
}

struct OverlayModifier: ViewModifier {
    let config: NavigationConfig
    let onDismiss: (() -> Void)?
    
    init(
        config: NavigationConfig = .default,
        onDismiss: (() -> Void)? = nil
    ) {
        self.config = config
        self.onDismiss = onDismiss
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Background effect
                if config.dismissOnTapOutside {
                    config.backgroundEffect.opacity > 0 ? Color.black.opacity(config.backgroundEffect.opacity)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            onDismiss?()
                        } : nil
                    
                    if config.backgroundEffect.blurRadius > 0 {
                        BlurView(style: .systemThinMaterial)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
                
                // Content
                Group {
                    let width = config.overlaySize.width(for: geometry)
                    let height = config.overlaySize.height(for: geometry)
                    
                    if width != nil || height != nil {
                        content
                            .frame(width: width, height: height, alignment: config.overlayAlignment)
                    } else {
                        content
                            .padding(config.overlayPadding)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(radius: 10)
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: config.overlayAlignment
                )
                .transition(config.customTransition ?? .scale.combined(with: .opacity))
                .animation(
                    config.customAnimation ?? .spring(
                        response: config.springResponse,
                        dampingFraction: config.springDampingFraction
                    ),
                    value: true
                )
            }
        }
    }
}

struct KeyboardResponsiveModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    private var cancellable: AnyCancellable?
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
    }
}

// MARK: - Layer Level Enum
enum LayerLevel: Int, CaseIterable {
    case first = 1      // Background content
    case second = 2     // Middle content
    case third = 3      // Top content
    
    var defaultCornerRadius: CGFloat {
        switch self {
        case .first: return 24
        case .second: return 16
        case .third: return 12
        }
    }
    
    var materialType: Material {
        switch self {
        case .first: return .regularMaterial
        case .second: return .thinMaterial
        case .third: return .ultraThinMaterial
        }
    }
}

// MARK: - Optimized Layered Background ViewModifier
struct LayeredBackground: ViewModifier {
    private var tabThemeColors: TabThemeColor
    private var level: LayerLevel
    private var cornerRadius: CGFloat?
    @Environment(\.colorScheme) private var colorScheme
    
    init(tabThemeColors: TabThemeColor, level: LayerLevel, cornerRadius: CGFloat? = nil) {
        self.tabThemeColors = tabThemeColors
        self.level = level
        self.cornerRadius = cornerRadius
    }
    
    private var effectiveCornerRadius: CGFloat {
        cornerRadius ?? level.defaultCornerRadius
    }
    
    // Tối ưu opacity calculations
    private var opacity: Double {
        let baseOpacity = colorScheme == .dark ? 0.15 : 0.08
        return baseOpacity * (1.0 - (Double(level.rawValue - 1) * 0.3))
    }
    
    // Tối ưu shadow properties
    private var shadowRadius: CGFloat {
        effectiveCornerRadius * 0.5
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .fill(level.materialType)
                    .overlay(
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tabThemeColors.secondaryColor.opacity(opacity * 0.5),
                                        tabThemeColors.primaryColor.opacity(opacity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .stroke(tabThemeColors.primaryColor, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Optimized Layered Card ViewModifier
struct LayeredCard: ViewModifier {
    private var tabThemeColors: TabThemeColor
    private var level: LayerLevel
    private var cornerRadius: CGFloat?
    @State private var isHovered: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let hoverAnimationDuration: Double = 0.2
    private let hoverScale: CGFloat = 1.02
    
    init(tabThemeColors: TabThemeColor, level: LayerLevel = .second, cornerRadius: CGFloat? = nil) {
        self.tabThemeColors = tabThemeColors
        self.level = level
        self.cornerRadius = cornerRadius
    }
    
    private var effectiveCornerRadius: CGFloat {
        cornerRadius ?? level.defaultCornerRadius
    }
    
    private var opacity: Double {
        let baseOpacity = colorScheme == .dark ? 0.15 : 0.08
        let hoverMultiplier = isHovered ? 1.3 : 1.0
        return baseOpacity * (1.0 - (Double(level.rawValue - 1) * 0.3)) * hoverMultiplier
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? hoverScale : 1.0)
            .background(
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .fill(level.materialType)
                    .overlay(
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .fill(tabThemeColors.softGradient(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .stroke(tabThemeColors.primaryColor, lineWidth: 1)
                    )
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: hoverAnimationDuration)) {
                    isHovered = hovering
                }
            }
            .animation(.easeInOut(duration: hoverAnimationDuration), value: isHovered)
    }
}

// MARK: - Optimized Layered Button ViewModifier
struct LayeredButton: ViewModifier {
    private var tabThemeColors: TabThemeColor
    private var level: LayerLevel
    private var cornerRadius: CGFloat?
    @State private var isPressed: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let pressAnimationDuration: Double = 0.1
    private let pressScale: CGFloat = 0.95
    private var action: () -> Void
    
    init(tabThemeColors: TabThemeColor, level: LayerLevel = .third, cornerRadius: CGFloat? = nil, action: @escaping () -> Void) {
        self.tabThemeColors = tabThemeColors
        self.level = level
        self.cornerRadius = cornerRadius
        self.action = action
    }
    
    private var effectiveCornerRadius: CGFloat {
        cornerRadius ?? level.defaultCornerRadius
    }
    
    private var opacity: Double {
        let baseOpacity = colorScheme == .dark ? 0.15 : 0.08
        let pressMultiplier = isPressed ? 1.5 : 1.0
        return baseOpacity * (1.0 - (Double(level.rawValue - 1) * 0.3)) * pressMultiplier
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressScale : 1.0)
            .background(
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .fill(level.materialType)
                    .overlay(
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .fill(tabThemeColors.gradient(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .stroke(tabThemeColors.primaryColor.opacity(opacity * 0.5), lineWidth: 0.5)
                    )
            )
            .onTapGesture {
                action()
                isPressed = true
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: pressAnimationDuration)) {
                            isPressed = false
                        }
                    }
            )
            .animation(.easeInOut(duration: pressAnimationDuration), value: isPressed)
    }
}

// MARK: - Layered Selection Button ViewModifier (with pressed effect)
struct LayeredSelectionButton: ViewModifier {
    private var tabThemeColors: TabThemeColor
    private var level: LayerLevel
    private var cornerRadius: CGFloat?
    private var isCapsule: Bool = false
    
    // Thay đổi từ @State thành thuộc tính thường để nhận từ parent
    private var isSelected: Bool
    
    // Thêm @State cho trạng thái pressed tạm thời
    @State private var isPressed: Bool = false
    
    // Thêm namespace để sử dụng matchedGeometryEffect
    private var namespace: Namespace.ID
    private var geometryID: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation properties
    private let selectedAnimationDuration: Double = 0.1
    private let selectedScale: CGFloat = 0.98
    private let selectedShadowMultiplier: CGFloat = 0.3
    
    // Action closure
    private var action: () -> Void
    
    init(
        tabThemeColors: TabThemeColor,
        level: LayerLevel = .first,
        cornerRadius: CGFloat? = nil,
        isCapsule: Bool = false,
        isSelected: Bool,
        namespace: Namespace.ID,
        geometryID: String,
        action: @escaping () -> Void
    ) {
        self.tabThemeColors = tabThemeColors
        self.level = level
        self.cornerRadius = cornerRadius
        self.action = action
        self.isCapsule = isCapsule
        self.isSelected = isSelected
        self.namespace = namespace
        self.geometryID = geometryID
    }
    
    private var effectiveCornerRadius: CGFloat {
        cornerRadius ?? level.defaultCornerRadius
    }
    
    // Sử dụng isActive để kết hợp cả isSelected và isPressed
    private var isActive: Bool {
        isSelected || isPressed
    }
    
    // Opacity calculations với pressed state
    private var primaryOpacity: (dark: Double, light: Double) {
        let baseOpacity = (dark: 0.15, light: 0.08)
        let levelMultiplier = 1.0 - (Double(level.rawValue - 1) * 0.3)
        let pressMultiplier = isActive ? 1.5 : 1.0
        return (
            dark: baseOpacity.dark * levelMultiplier * pressMultiplier,
            light: baseOpacity.light * levelMultiplier * pressMultiplier
        )
    }
    
    private var secondaryOpacity: (dark: Double, light: Double) {
        let baseOpacity = (dark: 0.12, light: 0.05)
        let levelMultiplier = 1.0 - (Double(level.rawValue - 1) * 0.3)
        let pressMultiplier = isActive ? 1.5 : 1.0
        return (
            dark: baseOpacity.dark * levelMultiplier * pressMultiplier,
            light: baseOpacity.light * levelMultiplier * pressMultiplier
        )
    }
    
    private var strokeOpacity: (primary: Double, secondary: Double) {
        let basePrimary = 0.2
        let baseSecondary = 0.1
        let levelMultiplier = 1.0 - (Double(level.rawValue - 1) * 0.25)
        let pressMultiplier = isActive ? 1.6 : 1.0
        return (
            primary: basePrimary * levelMultiplier * pressMultiplier,
            secondary: baseSecondary * levelMultiplier * pressMultiplier
        )
    }
    
    private var strokeWidth: CGFloat {
        let baseWidth: CGFloat = 1.0
        let levelWidth = baseWidth - (CGFloat(level.rawValue - 1) * 0.2)
        return isActive ? levelWidth * 1.3 : levelWidth
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? selectedScale : 1.0)
            .background(
                ZStack {
                    if isCapsule {
                        // Base material cho capsule
                        Capsule()
                            .fill(level.materialType)
                        
                        // Selected background với matchedGeometryEffect
                        if isSelected {
                            Capsule()
                                .fill(tabThemeColors.gradient(for: colorScheme))
                                .matchedGeometryEffect(id: geometryID, in: namespace)
                        } else {
                            Capsule()
                                .fill(tabThemeColors.softGradient(for: colorScheme))
                        }
                        
                        // Stroke border
                        Capsule()
                            .stroke(
                                tabThemeColors.gradient(for: colorScheme).opacity(isSelected ? 0.8 : 0.3),
                                lineWidth: strokeWidth
                            )
                    } else {
                        // Base material cho rounded rectangle
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .fill(level.materialType)
                        
                        // Selected background với matchedGeometryEffect
                        if isSelected {
                            RoundedRectangle(cornerRadius: effectiveCornerRadius)
                                .fill(tabThemeColors.gradient(for: colorScheme))
                                .matchedGeometryEffect(id: geometryID, in: namespace)
                        } else {
                            RoundedRectangle(cornerRadius: effectiveCornerRadius)
                                .fill(tabThemeColors.softGradient(for: colorScheme))
                        }
                        
                        // Stroke border
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .stroke(
                                tabThemeColors.gradient(for: colorScheme).opacity(isSelected ? 0.8 : 0.3),
                                lineWidth: strokeWidth
                            )
                    }
                }
            )
            .onTapGesture {
                // Execute action với haptic feedback
//                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
//                impactFeedback.impactOccurred()
                action()
                isPressed = true
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPressed = false
                        }
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
    }
}

// MARK: - Layered Alert Button ViewModifier (with pressed effect)
struct LayeredAlertButton: ViewModifier {
    private var cornerRadius: CGFloat?
    @State private var isPressed: Bool = false
    @State private var hasStroke: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation properties
    private let pressAnimationDuration: Double = 0.1
    private let pressScale: CGFloat = 0.95
    private let pressedShadowMultiplier: CGFloat = 0.3
    
    // Action closure
    private var action: () -> Void
    
    init(cornerRadius: CGFloat? = nil, hasStroke: Bool = false, action: @escaping () -> Void) {
        self.cornerRadius = cornerRadius
        self.hasStroke = hasStroke
        self.action = action
    }
    
    private var effectiveCornerRadius: CGFloat {
        cornerRadius ?? 24
    }
    
    // Opacity calculations với pressed state
    private var primaryOpacity: (dark: Double, light: Double) {
        let baseOpacity = (dark: 0.15, light: 0.08)
        let levelMultiplier = 0.7
        let pressMultiplier = isPressed ? 1.5 : 1.0
        return (
            dark: baseOpacity.dark * levelMultiplier * pressMultiplier,
            light: baseOpacity.light * levelMultiplier * pressMultiplier
        )
    }
    
    private var secondaryOpacity: (dark: Double, light: Double) {
        let baseOpacity = (dark: 0.12, light: 0.05)
        let levelMultiplier = 0.7
        let pressMultiplier = isPressed ? 1.5 : 1.0
        return (
            dark: baseOpacity.dark * levelMultiplier * pressMultiplier,
            light: baseOpacity.light * levelMultiplier * pressMultiplier
        )
    }
    
    private var strokeOpacity: (primary: Double, secondary: Double) {
        let basePrimary = 0.2
        let baseSecondary = 0.1
        let levelMultiplier = 0.75
        let pressMultiplier = isPressed ? 1.6 : 1.0
        return (
            primary: basePrimary * levelMultiplier * pressMultiplier,
            secondary: baseSecondary * levelMultiplier * pressMultiplier
        )
    }
    
    private var strokeWidth: CGFloat {
        let levelWidth: CGFloat = 0.8
        return isPressed ? levelWidth * 1.3 : levelWidth
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressScale : 1.0)
            .background(
                ZStack {
                    // Base material
                    if hasStroke {
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .fill(.thinMaterial)
                        
                        // Gradient overlay
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .fill(.red.gradient.opacity(colorScheme == .dark ? primaryOpacity.dark : primaryOpacity.light))
                        
                        // Stroke border
                        RoundedRectangle(cornerRadius: effectiveCornerRadius)
                            .stroke(.red, lineWidth: strokeWidth)
                    } else {
                        Capsule()
                            .fill(.red.opacity(0.8))
                    }
                }
            )
            .onTapGesture {
                action()
                isPressed = true
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: pressAnimationDuration)) {
                            isPressed = false
                        }
                    }
            )
            .animation(.easeInOut(duration: pressAnimationDuration), value: isPressed)
    }
}

// MARK: - Layered Conditional Button ViewModifier (with pressed effect)

struct LayeredTextFieldBackground: ViewModifier {
    private var tabThemeColors: TabThemeColor
    private var cornerRadius: CGFloat?
    
    init(tabThemeColors: TabThemeColor, cornerRadius: CGFloat? = nil) {
        self.tabThemeColors = tabThemeColors
        self.cornerRadius = cornerRadius
    }
    
    var effectiveCornerRadius: CGFloat {
        cornerRadius ?? 24
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .stroke(tabThemeColors.primaryColor.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Layered Text Field With Focused

struct LayeredFocusTextField: ViewModifier {
    private let themeColors: TabThemeColor
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let field: AppTextField
    private let focusField: FocusState<AppTextField?>.Binding
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        themeColors: TabThemeColor,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        field: AppTextField,
        focusField: FocusState<AppTextField?>.Binding
    ) {
        self.themeColors = themeColors
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.field = field
        self.focusField = focusField
    }
    
    func body(content: Content) -> some View {
        content
            .focused(focusField, equals: field)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeColors.primaryColor.opacity(0.3),
                                Color.primary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        focusField.wrappedValue == field ? themeColors.secondaryColor : Color.systemGray6.opacity(0.5),
                        lineWidth: 1
                    )
            }
    }
}
