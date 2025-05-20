//
//  PrinterService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import Foundation

final class PrinterService: PrinterServiceProtocol {
    
    static let shared = PrinterService()
    var isLoading: Bool = false
    var error: (any Error)?
    
    func printReceipt(for order: Order) async throws {
        
    }
    
    func printDailyReport() async throws {
        
    }
}
