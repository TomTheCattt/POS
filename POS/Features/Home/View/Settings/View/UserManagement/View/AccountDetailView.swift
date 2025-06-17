//
//  AccountDetailView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 28/5/25.
//

import SwiftUI
import PhotosUI

struct AccountDetailView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header với animation
                HStack {
                    Text("Thông tin tài khoản")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Profile Image Section với hiệu ứng
                profileImageSection
                    .padding(.vertical, 20)
                
                // Information Card
                VStack(spacing: 24) {
                    // Thời gian tạo tài khoản
                    HStack {
                        Label("Ngày tạo tài khoản", systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(appState.sourceModel.currentUser?.createdAt.formatted(date: .abbreviated, time: .shortened) ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // User Information Section
                    informationSection
                    
                    // Update Button
                    updateButton
                }
                .padding(24)
                .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .padding(.horizontal)
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedImage)
                .ignoresSafeArea()
                .onDisappear {
                    if let image = selectedImage {
                        Task {
                            //await viewModel.updateProfileImage(image)
                        }
                    }
                }
        }
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .onAppear {
            appState.sourceModel.setupCurrentUserListener()
        }
        .onDisappear {
            appState.sourceModel.removeCurrentUserListener()
        }
    }
    
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Circle
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 150, height: 150)
                    //.shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                // Profile Image
                Group {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                            .transition(.scale.combined(with: .opacity))
                    } else if let photoURL = viewModel.avatarUrl {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .transition(.scale.combined(with: .opacity))
                        } placeholder: {
                            ProgressView()
                                .frame(width: 40, height: 40)
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .foregroundColor(.gray)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                )
                
                // Camera Button với animation
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isShowingImagePicker = true
                    }
                } label: {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                        //.shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                }
                .offset(x: 50, y: 50)
                .transition(.scale.combined(with: .opacity))
            }
            
            if appState.sourceModel.isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Đang tải ảnh lên...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        //.shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                )
            }
        }
    }
    
    private var informationSection: some View {
        VStack(spacing: 24) {
            CustomTextField(
                title: "Tên hiển thị",
                text: $viewModel.fullName,
                icon: "person.fill",
                placeholder: "Nhập tên hiển thị"
            )
            
            CustomTextField(
                title: "Email",
                text: $viewModel.email,
                icon: "envelope.fill",
                placeholder: "Email của bạn",
                isDisabled: true
            )
            .textInputAutocapitalization(.never)
        }
    }
    
    private var updateButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.updateProfile()
                } catch {
                    appState.sourceModel.showError("Có lỗi xảy ra: \(error.localizedDescription)")
                }
            }
        } label: {
            HStack {
                if appState.sourceModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text("Cập nhật thông tin")
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme))
                    //.shadow(color: appState.sourceModel.currentThemeColors.settings.primaryColor.opacity(0.3), radius: 10, y: 5)
            )
        }
        .disabled(appState.sourceModel.isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CustomTextField: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    @Binding var text: String
    let icon: String
    var placeholder: String
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isDisabled ? .gray : .blue)
                    .frame(width: 24)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.7 : 1)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color(.systemGray6) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    //.shadow(color: .black.opacity(0.03), radius: 5, y: 2)
            )
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

//#Preview {
//    AccountDetailView()
//}
