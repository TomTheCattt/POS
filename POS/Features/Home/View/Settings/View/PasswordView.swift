import SwiftUI

struct PasswordView: View {
    @StateObject var viewModel: PasswordViewModel
    @EnvironmentObject private var appState: AppState
    @FocusState private var focusedField: Field?
    
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
                // Account Password Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mật khẩu tài khoản")
                        .font(.headline)
                    
                    SecureField("Mật khẩu hiện tại", text: $viewModel.currentPassword)
                        .keyboardType(.default)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .currentPassword)
                    
                    SecureField("Mật khẩu mới", text: $viewModel.newPassword)
                        .keyboardType(.default)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .newPassword)
                    
                    SecureField("Xác nhận mật khẩu mới", text: $viewModel.confirmPassword)
                        .keyboardType(.default)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .confirmPassword)
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.updateAccountPassword()
                                appState.sourceModel.showSuccess("Cập nhật mật khẩu tài khoản thành công")
                            } catch {
                                appState.sourceModel.showError(error.localizedDescription)
                            }
                        }
                    } label: {
                        Text("Cập nhật mật khẩu tài khoản")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.isAccountPasswordValid)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
                
                // Owner Password Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mật khẩu chủ cửa hàng")
                        .font(.headline)
                    
                    SecureField("Mật khẩu chủ cửa hàng hiện tại", text: $viewModel.currentOwnerPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .focused($focusedField, equals: .currentOwnerPassword)
                    
                    SecureField("Mật khẩu chủ cửa hàng mới", text: $viewModel.newOwnerPassword)
                        .keyboardType(.default)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .newOwnerPassword)
                    
                    SecureField("Xác nhận mật khẩu chủ cửa hàng mới", text: $viewModel.confirmOwnerPassword)
                        .keyboardType(.default)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .confirmOwnerPassword)
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.updateOwnerPassword()
                                appState.sourceModel.showSuccess("Cập nhật mật khẩu chủ cửa hàng thành công")
                            } catch {
                                appState.sourceModel.showError(error.localizedDescription)
                            }
                        }
                    } label: {
                        Text("Cập nhật mật khẩu chủ cửa hàng")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.isOwnerPasswordValid)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
            }
            .padding()
            .padding(.bottom, 100) // Thêm padding bottom để tránh bàn phím che nội dung
        }
        .scrollDismissesKeyboard(.immediately)
        .ignoresSafeArea(.keyboard) // Ngăn keyboard đẩy view
        .onTapGesture {
            focusedField = nil // Đóng bàn phím khi tap ra ngoài
        }
    }
}
