import Foundation
import SwiftUI

// MARK: - Overlay Size Configuration
enum OverlaySize {
    case small
    case medium
    case large
    case custom(width: CGFloat, height: CGFloat)
    case flexible
    
    func width(for geometry: GeometryProxy) -> CGFloat? {
        switch self {
        case .small:
            return min(300, geometry.size.width * 0.7)
        case .medium:
            return min(400, geometry.size.width * 0.8)
        case .large:
            return min(500, geometry.size.width * 0.9)
        case .custom(let width, _):
            return width
        case .flexible:
            return nil
        }
    }
    
    func height(for geometry: GeometryProxy) -> CGFloat? {
        switch self {
        case .small:
            return min(200, geometry.size.height * 0.3)
        case .medium:
            return min(300, geometry.size.height * 0.5)
        case .large:
            return min(400, geometry.size.height * 0.7)
        case .custom(_, let height):
            return height
        case .flexible:
            return nil
        }
    }
}

// MARK: - Navigation Configuration
struct NavigationConfig {
    // Cấu hình chung
    var isAnimated: Bool = true
    var shouldDismissPrevious: Bool = false
    var completion: (() -> Void)? = nil
    
    // Cấu hình cho overlay và sheet
    var autoDismiss: Bool = false
    var autoDismissDelay: TimeInterval = 2.0
    var dismissOnTapOutside: Bool = true
    var backgroundEffect: BackgroundEffect = .dim(opacity: 0.3)
    var overlaySize: OverlaySize = .flexible
    var overlayAlignment: Alignment = .center
    var overlayPadding: CGFloat = 20
    
    // Cấu hình animation
    var customAnimation: Animation?
    var customTransition: AnyTransition?
    var animationDuration: TimeInterval = 0.3
    var springResponse: Double = 0.3
    var springDampingFraction: Double = 0.8
    
    // Cấu hình presentation
    var detents: [UISheetPresentationController.Detent] = [.medium()]
    var prefersGrabberVisible: Bool = true
    var prefersScrollingExpandsWhenScrolledToEdge: Bool = true
    var prefersEdgeAttachedInCompactHeight: Bool = true
    var widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = true
    
    // Cấu hình gesture
    var enableDragToDismiss: Bool = true
    var enableSwipeGesture: Bool = true
    var swipeToPopGestureEnabled: Bool = true
    
    // Khởi tạo mặc định
    static let `default` = NavigationConfig()
    
    // Khởi tạo cho overlay
    static let overlay = NavigationConfig(
        autoDismiss: true,
        dismissOnTapOutside: true,
        backgroundEffect: .dim(opacity: 0.5),
        overlaySize: .flexible
    )
    
    // Khởi tạo cho sheet
    static let sheet = NavigationConfig(
        dismissOnTapOutside: true,
        backgroundEffect: .dim(opacity: 0.3),
        overlaySize: .large,
        detents: [.medium(), .large()]
    )
    
    // Khởi tạo cho alert/toast
    static let alert = NavigationConfig(
        autoDismiss: true,
        autoDismissDelay: 2.0,
        dismissOnTapOutside: true,
        backgroundEffect: .dim(opacity: 0.3),
        overlaySize: .small
    )
    
    // Khởi tạo tùy chỉnh
    init(
        isAnimated: Bool = true,
        shouldDismissPrevious: Bool = false,
        completion: (() -> Void)? = nil,
        autoDismiss: Bool = false,
        autoDismissDelay: TimeInterval = 2.0,
        dismissOnTapOutside: Bool = true,
        backgroundEffect: BackgroundEffect = .dim(opacity: 0.3),
        overlaySize: OverlaySize = .flexible,
        overlayAlignment: Alignment = .center,
        overlayPadding: CGFloat = 20,
        customAnimation: Animation? = nil,
        customTransition: AnyTransition? = nil,
        animationDuration: TimeInterval = 0.3,
        springResponse: Double = 0.3,
        springDampingFraction: Double = 0.8,
        detents: [UISheetPresentationController.Detent] = [.medium()],
        prefersGrabberVisible: Bool = true,
        prefersScrollingExpandsWhenScrolledToEdge: Bool = true,
        prefersEdgeAttachedInCompactHeight: Bool = true,
        widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = true,
        enableDragToDismiss: Bool = true,
        enableSwipeGesture: Bool = true,
        swipeToPopGestureEnabled: Bool = true
    ) {
        self.isAnimated = isAnimated
        self.shouldDismissPrevious = shouldDismissPrevious
        self.completion = completion
        self.autoDismiss = autoDismiss
        self.autoDismissDelay = autoDismissDelay
        self.dismissOnTapOutside = dismissOnTapOutside
        self.backgroundEffect = backgroundEffect
        self.overlaySize = overlaySize
        self.overlayAlignment = overlayAlignment
        self.overlayPadding = overlayPadding
        self.customAnimation = customAnimation
        self.customTransition = customTransition
        self.animationDuration = animationDuration
        self.springResponse = springResponse
        self.springDampingFraction = springDampingFraction
        self.detents = detents
        self.prefersGrabberVisible = prefersGrabberVisible
        self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
        self.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
        self.widthFollowsPreferredContentSizeWhenEdgeAttached = widthFollowsPreferredContentSizeWhenEdgeAttached
        self.enableDragToDismiss = enableDragToDismiss
        self.enableSwipeGesture = enableSwipeGesture
        self.swipeToPopGestureEnabled = swipeToPopGestureEnabled
    }
}
