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
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header
                Text("Thông tin tài khoản")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Profile Image Section
                profileImageSection
                    .padding(.bottom)
                
                // Information Card
                VStack(spacing: 24) {
                    // User Information Section
                    informationSection
                    
                    // Update Button
                    updateButton
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10)
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $viewModel.isShowingImagePicker) {
//            PhotosPicker(selection: $viewModel.imageSelection,
//                        matching: .images,
//                        photoLibrary: .shared()) {
//                Text("Chọn ảnh")
//            }
        }
    }
    
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                } else if let photoURL = viewModel.avatarUrl {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .frame(width: 40, height: 40)
                    }
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .foregroundColor(.gray)
                }
                
                // Camera Button
                Button {
                    viewModel.isShowingImagePicker = true
                } label: {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
                .offset(x: 45, y: 45)
            }
            
            if appState.sourceModel.isLoading {
                ProgressView("Đang tải ảnh lên...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
    
    private var informationSection: some View {
        VStack(spacing: 20) {
            CustomTextField(
                title: "Tên hiển thị",
                text: $viewModel.fullName,
                icon: "person.fill"
            )
            
            CustomTextField(
                title: "Email",
                text: $viewModel.email,
                icon: "envelope.fill"
            )
            .textInputAutocapitalization(.never)
            .disabled(true) // Email không thể thay đổi
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
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 4)
            )
        }
        .disabled(appState.sourceModel.isLoading)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                TextField(title, text: $text)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

//struct ImagePicker: UIViewControllerRepresentable {
//    @Binding var image: UIImage?
//    @Environment(\.presentationMode) var presentationMode
//    
//    func makeUIViewController(context: Context) -> PHPickerViewController {
//        var config = PHPickerConfiguration()
//        config.filter = .images
//        let picker = PHPickerViewController(configuration: config)
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, PHPickerViewControllerDelegate {
//        let parent: ImagePicker
//        
//        init(_ parent: ImagePicker) {
//            self.parent = parent
//        }
//        
//        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//            parent.presentationMode.wrappedValue.dismiss()
//            
//            guard let provider = results.first?.itemProvider else { return }
//            
//            if provider.canLoadObject(ofClass: UIImage.self) {
//                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
//                    Task { @MainActor in
//                        self?.parent.image = image as? UIImage
//                    }
//                }
//            }
//        }
//    }
//}

//#Preview {
//    AccountDetailView()
//}
