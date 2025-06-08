import SwiftUI

struct OwnerAuthView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SettingsViewModel
    @FocusState private var isPasswordFocused: Bool
    
    // Animation states
    @State private var showContent = false
    @State private var isShaking = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                if appState.sourceModel.isOwnerAuthenticated ?? false {
                    authenticatedView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                } else {
                    loginView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                }
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Xác thực chủ cửa hàng")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            appState.coordinator.dismiss(style: .present)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    showContent = true
                }
            }
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
                        .scaleEffect(showContent ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2), value: showContent)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Đã xác thực")
                            .font(.headline)
                        Text("Bạn đang được cấp quyền chủ cửa hàng")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: showContent)
                    
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
                .scaleEffect(showContent ? 1 : 0.9)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4), value: showContent)
                
                // Nút đăng xuất
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        appState.sourceModel.logoutAsOwner()
                    }
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
                .scaleEffect(showContent ? 1 : 0.9)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.5), value: showContent)
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
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.6 + Double(Array(OwnerPermission.allCases).firstIndex(of: permission) ?? 0) * 0.1), value: showContent)
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
        Group {
            if let lockEndTimeRemaining = appState.sourceModel.lockEndTimeRemaining {
                // Locked State View
                ScrollView {
                    VStack(spacing: 24) {
                        // Lock Status Card
                        VStack(spacing: 20) {
                            // Lock Icon with animation
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(showContent ? 1 : 0.5)
                                
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.red)
                                    .rotationEffect(.degrees(isShaking ? 0 : -8))
                                    .offset(x: isShaking ? -5 : 5)
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2), value: showContent)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                    isShaking.toggle()
                                }
                            }
                            
                            VStack(spacing: 12) {
                                Text("Tài khoản đã bị khóa")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Do nhập sai mật khẩu quá nhiều lần")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: showContent)
                            
                            // Countdown Timer Display
                            VStack(spacing: 8) {
                                Text("Thời gian còn lại")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                Text(lockEndTimeRemaining)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                            .padding(.top, 8)
                            .scaleEffect(showContent ? 1 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4), value: showContent)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 10)
                        )
                        .padding(.horizontal)
                        
                        // Info Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Thông tin")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                bulletPoint("Bạn chỉ có thể thực hiện đăng nhập lại sau khi hết thời gian chờ")
                                bulletPoint("Vui lòng đợi hoặc liên hệ quản trị viên")
                                bulletPoint("Không thử đăng nhập trong thời gian khóa")
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 10)
                        )
                        .padding(.horizontal)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.5), value: showContent)
                    }
                    .padding(.vertical)
                }
            } else {
                // Normal Login View
                ScrollView {
                    VStack(spacing: 24) {
                        // Login Card
                        VStack(spacing: 20) {
                            // Icon
                            Image(systemName: "lock.shield")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .padding(.bottom)
                                .scaleEffect(showContent ? 1 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: showContent)
                            
                            Text("Nhập mật khẩu chủ cửa hàng để tiếp tục")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: showContent)
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mật khẩu chủ cửa hàng")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 12) {
                                    Group {
                                        if viewModel.showPassword {
                                            TextField("Nhập mật khẩu", text: $viewModel.ownerPassword)
                                        } else {
                                            SecureField("Nhập mật khẩu", text: $viewModel.ownerPassword)
                                        }
                                    }
                                    .textFieldStyle(.plain)
                                    .focused($isPasswordFocused)
                                    
                                    Button {
                                        withAnimation {
                                            viewModel.showPassword.toggle()
                                        }
                                    } label: {
                                        Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
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
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4), value: showContent)
                            
                            // Login Button
                            Button {
                                viewModel.authenticateOwner()
                                if viewModel.authAttempts != 0 {
                                    appState.sourceModel.showError("Mật khẩu không chính xác. Còn \(3 - viewModel.authAttempts) lần thử.")
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
                            .disabled(viewModel.ownerPassword.isEmpty || appState.sourceModel.isLoading)
                            .scaleEffect(showContent ? 1 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.5), value: showContent)
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
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.6), value: showContent)
                    }
                    .padding(.vertical)
                }
            }
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
