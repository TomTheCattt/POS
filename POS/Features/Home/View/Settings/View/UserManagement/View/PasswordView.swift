import SwiftUI

struct PasswordView: View {
    @ObservedObject private var viewModel: PasswordViewModel
    @EnvironmentObject private var appState: AppState
    @FocusState private var focusedField: Field?
    @Environment(\.colorScheme) var colorScheme
    
    enum Field {
        case currentPassword
        case newPassword
        case confirmPassword
        case currentOwnerPassword
        case newOwnerPassword
        case confirmOwnerPassword
    }
    
    init(viewModel: PasswordViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header
                HStack {
                    Text("Đổi mật khẩu")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28))
                        .foregroundColor(appState.sourceModel.currentThemeColors.settings.primaryColor)
                }
                .padding(.horizontal)
                
                // Account Password Section
                passwordSection(
                    title: "Mật khẩu tài khoản",
                    description: "Mật khẩu dùng để đăng nhập vào ứng dụng",
                    icon: "lock.fill",
                    currentPassword: $viewModel.currentPassword,
                    newPassword: $viewModel.newPassword,
                    confirmPassword: $viewModel.confirmPassword,
                    currentField: .currentPassword,
                    newField: .newPassword,
                    confirmField: .confirmPassword,
                    isValid: viewModel.isAccountPasswordValid,
                    action: updateAccountPassword
                )
                
                // Owner Password Section
                passwordSection(
                    title: "Mật khẩu chủ cửa hàng",
                    description: "Mật khẩu dùng để xác thực các thao tác quan trọng",
                    icon: "key.fill",
                    currentPassword: $viewModel.currentOwnerPassword,
                    newPassword: $viewModel.newOwnerPassword,
                    confirmPassword: $viewModel.confirmOwnerPassword,
                    currentField: .currentOwnerPassword,
                    newField: .newOwnerPassword,
                    confirmField: .confirmOwnerPassword,
                    isValid: viewModel.isOwnerPasswordValid,
                    action: updateOwnerPassword
                )
            }
            .padding(.vertical)
        }
        .padding(.horizontal)
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .scrollDismissesKeyboard(.immediately)
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func passwordSection(
        title: String,
        description: String,
        icon: String,
        currentPassword: Binding<String>,
        newPassword: Binding<String>,
        confirmPassword: Binding<String>,
        currentField: Field,
        newField: Field,
        confirmField: Field,
        isValid: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(appState.sourceModel.currentThemeColors.settings.primaryColor)
                    Text(title)
                        .font(.headline)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Password Fields
            VStack(spacing: 20) {
                CustomSecureField(
                    title: "Mật khẩu hiện tại",
                    text: currentPassword,
                    isFocused: focusedField == currentField,
                    onFocus: { focusedField = currentField }
                )
                
                CustomSecureField(
                    title: "Mật khẩu mới",
                    text: newPassword,
                    isFocused: focusedField == newField,
                    onFocus: { focusedField = newField }
                )
                
                CustomSecureField(
                    title: "Xác nhận mật khẩu mới",
                    text: confirmPassword,
                    isFocused: focusedField == confirmField,
                    onFocus: { focusedField = confirmField }
                )
            }
            
            // Password Requirements
            if !newPassword.wrappedValue.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Yêu cầu mật khẩu:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    PasswordRequirementRow(
                        text: "Ít nhất 8 ký tự",
                        isMet: newPassword.wrappedValue.count >= 8
                    )
                    
                    PasswordRequirementRow(
                        text: "Chứa chữ hoa và chữ thường",
                        isMet: newPassword.wrappedValue.containsUppercase && newPassword.wrappedValue.containsLowercase
                    )
                    
                    PasswordRequirementRow(
                        text: "Chứa ít nhất 1 số",
                        isMet: newPassword.wrappedValue.containsNumber
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Update Button
            Button(action: action) {
                HStack {
                    if appState.sourceModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                    Text("Cập nhật \(title.lowercased())")
                        .fontWeight(.semibold)
                    if isValid {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isValid ? appState.sourceModel.currentThemeColors.settings.primaryColor : Color.gray.opacity(0.5))
                        //.shadow(color: isValid ? appState.sourceModel.currentThemeColors.settings.primaryColor.opacity(0.3) : Color.clear, radius: 10, y: 5)
                )
            }
            .disabled(!isValid || appState.sourceModel.isLoading)
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(24)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
        .padding(.horizontal)
    }
    
    private func updateAccountPassword() {
        Task {
            do {
                try await viewModel.updateAccountPassword()
                appState.sourceModel.showSuccess("Cập nhật mật khẩu tài khoản thành công")
                clearFields(.account)
            } catch {
                appState.sourceModel.showError(error.localizedDescription)
            }
        }
    }
    
    private func updateOwnerPassword() {
        Task {
            do {
                try await viewModel.updateOwnerPassword()
                appState.sourceModel.showSuccess("Cập nhật mật khẩu chủ cửa hàng thành công")
                clearFields(.owner)
            } catch {
                appState.sourceModel.showError(error.localizedDescription)
            }
        }
    }
    
    private func clearFields(_ type: PasswordType) {
        switch type {
        case .account:
            viewModel.currentPassword = ""
            viewModel.newPassword = ""
            viewModel.confirmPassword = ""
        case .owner:
            viewModel.currentOwnerPassword = ""
            viewModel.newOwnerPassword = ""
            viewModel.confirmOwnerPassword = ""
        }
        focusedField = nil
    }
    
    private enum PasswordType {
        case account
        case owner
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let isFocused: Bool
    let onFocus: () -> Void
    @State private var isSecure: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Group {
                    if isSecure {
                        SecureField(title, text: $text)
                    } else {
                        TextField(title, text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .onTapGesture {
                    onFocus()
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSecure.toggle()
                    }
                } label: {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(isFocused ? .blue : .gray)
                        .frame(width: 24)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
            Text(text)
                .font(.subheadline)
                .foregroundColor(isMet ? .primary : .gray)
        }
    }
}

