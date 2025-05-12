//
//  FunctionService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

final class FunctionsService: FunctionsServiceProtocol {
    func generateDailyReport(completion: @escaping (Result<Void, AppError>) -> Void) {
        
    }
    
    func generateWeeklyReport(completion: @escaping (Result<Void, AppError>) -> Void) {
        
    }
    
    func generateMonthlyReport(completion: @escaping (Result<Void, AppError>) -> Void) {
        
    }
    
    func createPDFInvoice(for order: Order, completion: @escaping (Result<URL, AppError>) -> Void) {
        
    }
    
    func logCustomEvent(name: String, params: [String : Any]?) {
        
    }
    
    func detectUnusualActivity(completion: @escaping (Result<Void, AppError>) -> Void) {
        
    }
    
    func validateDiscountCode(_ code: String, completion: @escaping (Result<Double, AppError>) -> Void) {
        
    }
    
    func applyLoyaltyPoints(userID: String, orderTotal: Double, completion: @escaping (Result<Double, AppError>) -> Void) {
        
    }
    
    func backupDatabaseSnapshot(completion: @escaping (Result<Void, AppError>) -> Void) {
        
    }
    
    func resetCashierDisplayNames(completion: @escaping (Result<Void, AppError>) -> Void) {
        
    }
}
