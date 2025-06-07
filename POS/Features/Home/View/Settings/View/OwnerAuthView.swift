import SwiftUI

struct OwnerAuthView: View {
    @EnvironmentObject private var appState: AppState
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @FocusState private var isPasswordFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                if appState.sourceModel.isOwnerAuthenticated ?? false {
                    authenticatedView
                } else {
                    loginView
                }
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Xác thực chủ cửa hàng")
            .navigationBarItems(
                leading: Button("Đóng") { appState.coordinator.dismiss(style: .present) }
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var authenticatedView: some View {
        VStack(spacing: 24) {
            // Status Card
            VStack(spacing: 20) {
                // Icon và Status
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Đã xác thực")
                            .font(.headline)
                        Text("Bạn đang được cấp quyền chủ cửa hàng")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Thời gian còn lại
                VStack(spacing: 8) {
                    Text("Thời gian còn lại")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(appState.sourceModel.remainingTimeString)
                        .font(.title3.monospacedDigit())
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                
                // Nút đăng xuất
                Button {
                    appState.sourceModel.logoutAsOwner()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Đăng xuất khỏi quyền chủ cửa hàng")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
            .padding(.horizontal)
            
            // Permissions Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Quyền hạn của chủ cửa hàng")
                    .font(.headline)
                
                ForEach(OwnerPermission.allCases, id: \.self) { permission in
                    HStack(spacing: 12) {
                        Image(systemName: permission.icon)
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text(permission.description)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
            .padding(.horizontal)
        }
    }
    
    private var loginView: some View {
        VStack(spacing: 24) {
            // Login Card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "lock.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                Text("Nhập mật khẩu chủ cửa hàng để tiếp tục")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mật khẩu chủ cửa hàng")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Group {
                            if showPassword {
                                TextField("Nhập mật khẩu", text: $password)
                            } else {
                                SecureField("Nhập mật khẩu", text: $password)
                            }
                        }
                        .textFieldStyle(.plain)
                        .focused($isPasswordFocused)
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isPasswordFocused ? Color.blue : Color.clear, lineWidth: 1)
                            )
                    )
                }
                
                // Login Button
                Button {
                    if appState.sourceModel.authenticateAsOwner(password: password) {
                        password = ""
                        isPasswordFocused = false
                    } else {
                        // Hiển thị lỗi
                        appState.sourceModel.showError("Mật khẩu không chính xác")
                    }
                } label: {
                    HStack {
                        if appState.sourceModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text("Xác thực")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .disabled(password.isEmpty || appState.sourceModel.isLoading)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
            .padding(.horizontal)
            
            // Info Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Lưu ý")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    bulletPoint("Quyền chủ cửa hàng sẽ tự động hết hạn sau 1 giờ")
                    bulletPoint("Bạn có thể đăng xuất bất cứ lúc nào")
                    bulletPoint("Chỉ sử dụng quyền này khi cần thiết")
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
            .padding(.horizontal)
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.blue)
                .padding(.top, 7)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Types
enum OwnerPermission: CaseIterable {
    case manageShops
    case viewFinancials
    case manageStaff
    case systemSettings
    
    var icon: String {
        switch self {
        case .manageShops: return "building.2"
        case .viewFinancials: return "chart.bar"
        case .manageStaff: return "person.2"
        case .systemSettings: return "gearshape"
        }
    }
    
    var description: String {
        switch self {
        case .manageShops: return "Quản lý thêm/xóa cửa hàng"
        case .viewFinancials: return "Xem báo cáo tài chính"
        case .manageStaff: return "Quản lý nhân viên"
        case .systemSettings: return "Cài đặt hệ thống"
        }
    }
} 
