import Foundation
import SwiftUI

enum NavigationStyle: Codable {
    case push               // Push to new screen
    case present           // Present as sheet from bottom
    case overlay           // Present as overlay with custom animation
    case fullScreen        // Present full screen with custom transition
    case slideFromLeft     // Slide in from left
    case slideFromRight    // Slide in from right
    case slideFromBottom   // Slide in from bottom
    case slideFromTop      // Slide in from top
    case fade             // Fade in/out
    case scale            // Scale up/down
    
    // Animation configuration
    var animation: Animation {
        switch self {
        case .push:
            return .spring(response: 0.3, dampingFraction: 0.8)
        case .present:
            return .spring(response: 0.4, dampingFraction: 0.8)
        case .overlay:
            return .spring(response: 0.3, dampingFraction: 0.8)
        case .fullScreen:
            return .spring(response: 0.5, dampingFraction: 0.8)
        case .slideFromLeft, .slideFromRight:
            return .spring(response: 0.4, dampingFraction: 0.8)
        case .slideFromBottom, .slideFromTop:
            return .spring(response: 0.4, dampingFraction: 0.8)
        case .fade:
            return .easeInOut(duration: 0.3)
        case .scale:
            return .spring(response: 0.3, dampingFraction: 0.8)
        }
    }
    
    // Transition effect
    var transition: AnyTransition {
        switch self {
        case .push:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .present:
            return .asymmetric(
                insertion: .move(edge: .bottom),
                removal: .move(edge: .bottom)
            )
        case .overlay:
            return .asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            )
        case .fullScreen:
            return .asymmetric(
                insertion: .move(edge: .bottom),
                removal: .move(edge: .bottom)
            )
        case .slideFromLeft:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        case .slideFromRight:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .slideFromBottom:
            return .asymmetric(
                insertion: .move(edge: .bottom),
                removal: .move(edge: .bottom)
            )
        case .slideFromTop:
            return .asymmetric(
                insertion: .move(edge: .top),
                removal: .move(edge: .top)
            )
        case .fade:
            return .opacity
        case .scale:
            return .scale.combined(with: .opacity)
        }
    }
    
    // Background dimming configuration
    var backgroundEffect: BackgroundEffect {
        switch self {
        case .push:
            return .none
        case .present:
            return .dim(opacity: 0.3)
        case .overlay:
            return .dim(opacity: 0.5)
        case .fullScreen:
            return .none
        case .slideFromLeft, .slideFromRight:
            return .dim(opacity: 0.3)
        case .slideFromBottom, .slideFromTop:
            return .dim(opacity: 0.3)
        case .fade:
            return .blur(radius: 10)
        case .scale:
            return .dim(opacity: 0.4)
        }
    }
}

// Background effect options
enum BackgroundEffect {
    case none
    case dim(opacity: Double)
    case blur(radius: CGFloat)
    case both(opacity: Double, radius: CGFloat)
    
    var opacity: Double {
        switch self {
        case .none:
            return 0
        case .dim(let opacity):
            return opacity
        case .blur:
            return 0
        case .both(let opacity, _):
            return opacity
        }
    }
    
    var blurRadius: CGFloat {
        switch self {
        case .none, .dim:
            return 0
        case .blur(let radius):
            return radius
        case .both(_, let radius):
            return radius
        }
    }
}

// Extension for view modifiers

// Blur view using UIKit
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
