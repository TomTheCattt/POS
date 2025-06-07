import Combine
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ProfileViewModel: ObservableObject {
    private let source: SourceModel
    
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var avatarUrl: URL?
    @Published var isShowingImagePicker: Bool = false
    @Published var selectedImage: UIImage?
    
    init(source: SourceModel) {
        self.source = source
        source.currentUserPublisher
            .sink { [weak self] user in
                self?.fullName = user?.displayName ?? "Unknown User"
                self?.email = user?.email ?? "Unknown Email"
                self?.avatarUrl = user?.photoURL
            }
            .store(in: &source.cancellables)
    }
    
    func updateProfile() async throws {
        guard let currentUser = source.currentUser, let userId = currentUser.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])
        }
        
        do {
            try await source.withLoading {
                let _ = try await source.environment.databaseService.updateUser(AppUser(uid: currentUser.uid, email: email, displayName: fullName, photoURL: avatarUrl, ownerPassword: currentUser.ownerPassword, createdAt: currentUser.createdAt, updatedAt: Date()), userId: userId)
                source.showSuccess("Cập nhật thông tin thành công")
            }
        } catch {
            source.showError(error.localizedDescription)
        }
    }
    
    func deleteAvatar() async throws {
        guard let currentUser = source.currentUser, let userId = currentUser.id, let photoURL = currentUser.photoURL else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])
        }
        
        do {
            try await source.withLoading {
                if avatarUrl != nil {
                    try await source.environment.storageService.deleteImage(at: photoURL)
                    let _ = try await source.environment.databaseService.updateUser(AppUser(uid: currentUser.uid, email: email, displayName: fullName, photoURL: nil, ownerPassword: currentUser.ownerPassword, createdAt: currentUser.createdAt, updatedAt: Date()), userId: userId)
                    self.avatarUrl = nil
                    source.showSuccess("Đã xóa ảnh đại diện")
                }
            }
        } catch {
            source.showError(error.localizedDescription)
        }
    }
    
    func validateProfile() -> Bool {
        // Kiểm tra fullName không được trống
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            source.showError("Vui lòng nhập họ tên")
            return false
        }
        
        return true
    } 
}
