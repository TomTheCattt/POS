import SwiftUI

struct ToastView: View {
    let type: ToastType
    let message: String
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: type.iconName)
                    .foregroundColor(type.iconColor)
                Text(message)
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
//                    .shadow(radius: 5)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .transition(.move(edge: .bottom))
            Spacer()
        }
        .animation(.spring(), value: true)
        .zIndex(1)
    }
}

enum ToastType {
    case error
    case success
    case info
    
    var iconName: String {
        switch self {
        case .error:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .error:
            return .red
        case .success:
            return .green
        case .info:
            return .blue
        }
    }
} 
