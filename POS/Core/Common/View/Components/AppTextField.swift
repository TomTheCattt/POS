import SwiftUI

struct ShakeTextField: View {
    // MARK: - Properties
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    var borderColor: Color
    let isSecure: Bool
    let submitLabel: SubmitLabel
    @FocusState.Binding var focusField: AppTextField?
    let field: AppTextField
    @Binding var shakeAnimation: Bool
    let backgroundView: AnyView
    let overlayView: AnyView

    // MARK: - Initialization
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        borderColor: Color = .gray.opacity(0.5),
        isSecure: Bool = false,
        submitLabel: SubmitLabel = .done,
        focusField: FocusState<AppTextField?>.Binding,
        field: AppTextField,
        shakeAnimation: Binding<Bool>,
        backgroundView: AnyView = AnyView(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        ),
        overlayView: AnyView = AnyView(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.5), lineWidth: 1)
        )
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.borderColor = borderColor
        self.isSecure = isSecure
        self.submitLabel = submitLabel
        self._focusField = focusField
        self.field = field
        self._shakeAnimation = shakeAnimation
        self.backgroundView = backgroundView
        self.overlayView = overlayView
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .padding()
            .background(backgroundView)
            .overlay(overlayView)
            .modifier(ShakeEffect(shake: $shakeAnimation))
            .focused($focusField, equals: field)
            .submitLabel(submitLabel)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .id(field.id)
        }
    }
}

struct FormTextField: View {
    
    private let icon: String
    private let title: String
    private let placeholder: String
    @Binding private var text: String
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let field: AppTextField
    private let focusField: FocusState<AppTextField?>.Binding
    
    init(icon: String, title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, textContentType: UITextContentType? = nil, field: AppTextField, focusField: FocusState<AppTextField?>.Binding) {
        self.icon = icon
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.field = field
        self.focusField = focusField
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            TextField(placeholder, text: $text)
                .focused(focusField, equals: field)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
        }
    }
}

