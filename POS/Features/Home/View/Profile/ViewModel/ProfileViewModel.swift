import Combine
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Properties
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var avatarUrl: URL?
    
    private let source: SourceModel
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBinding()
    }
    
    // MARK: - Public Methods
    func setupBinding() {
        source.currentUserPublisher
            .sink { [weak self] currentUser in
                guard let self = self,
                      let currentUser = currentUser else { return }
                self.fullName = currentUser.displayName
                self.email = currentUser.email
                self.avatarUrl = currentUser.photoURL
            }
            .store(in: &source.cancellables)
    }
    
    func updateProfile() async throws {
        guard let user = source.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            try await source.withLoading {
                let newUser = AppUser(uid: user.uid, email: user.email, displayName: fullName, photoURL: user.photoURL, ownerPassword: user.ownerPassword, createdAt: user.createdAt, updatedAt: Date())
                let _ = try await source.environment.databaseService.updateUser(newUser, userId: user.id ?? "")
            }
        } catch {
            source.showError(error.localizedDescription)
        }
    }
    
    func updateProfileImage(_ image: UIImage) async throws {
        guard let userId = source.currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ProfileError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể xử lý ảnh"])
        }
        
        do {
            try await source.withLoading {
                let path = "user/\(userId)/\(UUID().uuidString)"
                let photoURL = try await source.environment.storageService.uploadImage(imageData, path: path)
                if let currentUser = source.currentUser {
                    var updateUser = currentUser
                    updateUser.photoURL = photoURL
                    updateUser.updatedAt = Date()
                    let _ = try await source.environment.databaseService.updateUser(updateUser, userId: userId)
                    avatarUrl = photoURL
                }
                
            }
        } catch {
            source.showError(error.localizedDescription)
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        let errorMessage: String
        switch error {
        case let storageError as StorageError:
            switch storageError {
            case .fileNotFound:
                errorMessage = "Không tìm thấy file ảnh"
            case .permissionDenied:
                errorMessage = "Không có quyền truy cập"
            default:
                errorMessage = "Lỗi khi tải ảnh lên: \(storageError.localizedDescription)"
            }
        case let firestoreError as FirestoreError:
            errorMessage = "Lỗi cập nhật dữ liệu: \(firestoreError.localizedDescription)"
        default:
            errorMessage = error.localizedDescription
        }
        
        source.showError(errorMessage)
    }
}

// MARK: - Custom Errors
extension ProfileViewModel {
    enum ProfileError: LocalizedError {
        case imageProcessingFailed
        case uploadFailed
        case updateFailed
        case userNotFound
        
        var errorDescription: String? {
            switch self {
            case .imageProcessingFailed:
                return "Không thể xử lý ảnh"
            case .uploadFailed:
                return "Không thể tải ảnh lên"
            case .updateFailed:
                return "Không thể cập nhật thông tin"
            case .userNotFound:
                return "Không tìm thấy thông tin người dùng"
            }
        }
    }
}
