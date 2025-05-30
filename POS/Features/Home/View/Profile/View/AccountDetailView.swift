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
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Profile Image Section
                VStack {
                    ZStack {
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else if let photoURL = viewModel.avatarUrl {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                        }
                        
                        Button {
                            viewModel.isShowingImagePicker = true
                        } label: {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: 40, y: 40)
                    }
                }
                .padding(.top, 20)
                
                // User Information Section
                VStack(spacing: 20) {
                    ProfileTextField(title: "Tên hiển thị", text: $viewModel.fullName)
                    ProfileTextField(title: "Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal)
                
                // Update Button
                Button {
                    Task {
                        do {
                            try await viewModel.updateProfile()
                        } catch {
                            appState.sourceModel.showError("Có lỗi xảy ra: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Cập nhật thông tin")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $viewModel.isShowingImagePicker) {
            //ImagePicker(image: $viewModel.selectedImage)
        }
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.gray)
            TextField(title, text: $text)
                .keyboardType(.default)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct SecureTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.gray)
            SecureField(title, text: $text)
                .keyboardType(.default)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
