import SwiftUI

struct PasswordView: View {
    @StateObject var viewModel: PasswordViewModel
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
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                Text("Đổi mật khẩu")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Account Password Section
                passwordSection(
                    title: "Mật khẩu tài khoản",
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
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.immediately)
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func passwordSection(
        title: String,
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
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            // Password Fields
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
            
            // Update Button
            Button(action: action) {
                HStack {
                    if appState.sourceModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                    Text("Cập nhật \(title.lowercased())")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isValid ? Color.blue : Color.gray)
                        .shadow(color: isValid ? Color.blue.opacity(0.3) : Color.clear, radius: 8, y: 4)
                )
            }
            .disabled(!isValid || appState.sourceModel.isLoading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
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
                .font(.subheadline)
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
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}
