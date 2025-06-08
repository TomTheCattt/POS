import Foundation
import FirebaseFirestore

@MainActor
class StaffViewModel: ObservableObject {
    @Published var staffList: [Staff] = []
    
    private let source: SourceModel
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBinding()
    }
    
    func setupBinding() {
        source.staffsPublisher
            .sink { [weak self] staffs in
                guard let self = self,
                      let staffs = staffs else { return }
                self.staffList = staffs
            }
            .store(in: &source.cancellables)
    }
    
    func createStaff(name: String, position: StaffPosition, hourlyRate: Double) async throws {
        do {
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                guard let shopId = source.activatedShop?.id else {
                    throw AppError.shop(.notFound)
                }
                // Validate input
                try Staff.validate(name: name, hourlyRate: hourlyRate)
                
                // Create new staff
                let staff = Staff(
                    name: name,
                    position: position,
                    hourlyRate: hourlyRate,
                    shopId: shopId,
                    shifts: [],
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                // Save to Firestore
                let _ = try await source.environment.databaseService.createStaff(staff, userId: userId, shopId: shopId)
            }
        } catch {
            source.handleError(error)
        }
    }
    
    func updateStaff(_ staff: Staff, name: String, position: StaffPosition, hourlyRate: Double) async throws {
        // Validate input
        do {
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                guard let shopId = source.activatedShop?.id else {
                    throw AppError.shop(.notFound)
                }
                // Validate input
                try Staff.validate(name: name, hourlyRate: hourlyRate)
                
                guard let staffId = staff.id else { return }
                
                let updatedStaff = Staff(name: name, position: position, hourlyRate: hourlyRate, shopId: shopId, shifts: [], createdAt: staff.createdAt, updatedAt: Date())
                
                let _ = try await source.environment.databaseService.updateStaff(updatedStaff, userId: userId, shopId: shopId, staffId: staffId)
            }
        } catch {
            source.handleError(error)
        }
    }
    
    func deleteStaff(_ staff: Staff) async throws {
        guard let staffId = staff.id else { return }
        do {
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                guard let shopId = source.activatedShop?.id else {
                    throw AppError.shop(.notFound)
                }
                try await source.environment.databaseService.deleteStaff(userId: userId, shopId: shopId, staffId: staffId)
            }
        }
    }
} 
