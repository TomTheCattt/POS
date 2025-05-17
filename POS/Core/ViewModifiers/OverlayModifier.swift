import SwiftUI

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
