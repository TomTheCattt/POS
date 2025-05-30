import SwiftUI
import Combine

@MainActor
final class PasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    
    @Published var currentOwnerPassword = ""
    @Published var newOwnerPassword = ""
    @Published var confirmOwnerPassword = ""
    
    @Published private(set) var isAccountPasswordValid = false
    @Published private(set) var isOwnerPasswordValid = false
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupValidation()
    }
    
    private func setupValidation() {
        // Validate account password
        Publishers.CombineLatest3($currentPassword, $newPassword, $confirmPassword)
            .map { current, new, confirm in
                !current.isEmpty && 
                !new.isEmpty && 
                !confirm.isEmpty && 
                new == confirm &&
                new.count >= 6
            }
            .assign(to: &$isAccountPasswordValid)
        
        // Validate owner password
        Publishers.CombineLatest3($currentOwnerPassword, $newOwnerPassword, $confirmOwnerPassword)
            .map { current, new, confirm in
                !current.isEmpty && 
                !new.isEmpty && 
                !confirm.isEmpty && 
                new == confirm &&
                new.count >= 6
            }
            .assign(to: &$isOwnerPasswordValid)
    }
    
    // MARK: - Public Methods
    func updateAccountPassword() async throws {
        guard let _ = source.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            try await source.environment.authService.updatePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            // Reset fields after successful update
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            source.handleError(error, action: "cập nhật mật khẩu tài khoản")
            throw error
        }
    }
    
    func updateOwnerPassword() async throws {
        guard let user = source.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let userId = user.id else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            // Verify current owner password
            guard user.ownerPassword == currentOwnerPassword else {
                throw AppError.auth(.wrongPassword)
            }
            
            // Create updated user with new owner password
            var updatedUser = user
            updatedUser.ownerPassword = newOwnerPassword
            
            let _ = try await source.environment.databaseService.updateUser(updatedUser, userId: userId)
            
            // Reset fields after successful update
            currentOwnerPassword = ""
            newOwnerPassword = ""
            confirmOwnerPassword = ""
        } catch {
            source.handleError(error, action: "cập nhật mật khẩu chủ cửa hàng")
            throw error
        }
    }
} 
