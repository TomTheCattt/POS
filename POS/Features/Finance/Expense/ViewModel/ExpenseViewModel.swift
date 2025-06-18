//
//  ExpenseViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 11/6/25.
//

import Foundation
import UIKit
import Combine

@MainActor
// MARK: - View Model
class ExpenseViewModel: ObservableObject {
    @Published var expenses: [ExpenseItem] = []
    @Published var isOwner: Bool = false
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    // MARK: - Computed Properties
    
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var approvedExpenses: Double {
        expenses.filter { $0.status == .approved }.reduce(0) { $0 + $1.amount }
    }
    
    var pendingExpenses: Double {
        expenses.filter { $0.status == .pending }.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Data Filtering
    
    func filteredRecurringExpenses(category: ExpenseCategory?) -> [GroupedExpenses] {
        let filtered = expenses.filter { expense in
            let categoryMatch = category == nil || expense.category == category
            let isRecurring = expense.isRecurring
            let needsRenewal = isNeedsRenewal(expense)
            return categoryMatch && isRecurring && needsRenewal
        }
        
        return groupExpensesByDate(filtered)
    }
    
    func filteredDailyExpenses(category: ExpenseCategory?) -> [GroupedExpenses] {
        let filtered = expenses.filter { expense in
            let categoryMatch = category == nil || expense.category == category
            return categoryMatch && !expense.isRecurring
        }
        
        return groupExpensesByDate(filtered)
    }
    
    private func isNeedsRenewal(_ expense: ExpenseItem) -> Bool {
        guard expense.isRecurring else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let expirationDate: Date
        
        switch expense.recurringType {
        case .monthly:
            expirationDate = calendar.date(byAdding: .month, value: 1, to: expense.expenseDate) ?? now
        case .quarterly:
            expirationDate = calendar.date(byAdding: .month, value: 3, to: expense.expenseDate) ?? now
        case .yearly:
            expirationDate = calendar.date(byAdding: .year, value: 1, to: expense.expenseDate) ?? now
        case .none:
            return false
        }
        
        let daysUntilExpiration = calendar.dateComponents([.day], from: now, to: expirationDate).day ?? 0
        return daysUntilExpiration <= 3
    }
    
    private func groupExpensesByDate(_ expenses: [ExpenseItem]) -> [GroupedExpenses] {
        let grouped = Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.expenseDate)
        }
        
        return grouped.map { date, items in
            GroupedExpenses(date: date, items: items.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Firebase Operations
    
    private func setupBindings() {
//        db.collection("expenses")
//            .whereField("shopId", isEqualTo: shopId)
//            .addSnapshotListener { [weak self] snapshot, error in
//                if let error = error {
//                    self?.error = error
//                    return
//                }
//
//                guard let documents = snapshot?.documents else { return }
//                self?.expenses = documents.compactMap { document in
//                    try? document.data(as: ExpenseItem.self)
//                }
//            }
        source.isOwnerAuthenticatedPublisher
            .sink { [weak self] isOwner in
                guard let self = self,
                      let isOwner = isOwner else { return }
                self.isOwner = isOwner
            }
            .store(in: &cancellables)
    }
    
    func addExpense(_ expense: ExpenseItem) async throws {
//        try await db.collection("expenses").addDocument(from: expense)
    }
    
    func approveExpense(_ expense: ExpenseItem) {
//        guard var updatedExpense = expense.copy() else { return }
//        updatedExpense.status = .approved
//        updatedExpense.approvedBy = currentUserId
//        updatedExpense.approvedAt = Date()
//        updatedExpense.updatedAt = Date()
//
//        do {
//            try db.collection("expenses").document(expense.id ?? "").setData(from: updatedExpense)
//        } catch {
//            self.error = error
//        }
    }
    
    func rejectExpense(_ expense: ExpenseItem) {
//        guard var updatedExpense = expense.copy() else { return }
//        updatedExpense.status = .rejected
//        updatedExpense.approvedBy = currentUserId
//        updatedExpense.approvedAt = Date()
//        updatedExpense.updatedAt = Date()
//
//        do {
//            try db.collection("expenses").document(expense.id ?? "").setData(from: updatedExpense)
//        } catch {
//            self.error = error
//        }
    }
    
    func uploadAttachment(_ image: UIImage) async throws -> String? {
//        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return nil }
//
//        let filename = "\(UUID().uuidString).jpg"
//        let ref = storage.reference().child("expenses/\(shopId)/\(filename)")
//
//        _ = try await ref.putDataAsync(imageData)
//        return try await ref.downloadURL().absoluteString
        return nil
    }
}

