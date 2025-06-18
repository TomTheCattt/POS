//
//  PrinterService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import Foundation
import CoreBluetooth

final class PrinterService: NSObject, PrinterServiceProtocol {
    
    // MARK: - Singleton
    static let shared = PrinterService()
    
    // MARK: - Properties
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: (any Error)?
    
    private var centralManager: CBCentralManager?
    private var printerPeripheral: CBPeripheral?
    private var printerCharacteristic: CBCharacteristic?
    private var printQueue: [Data] = []
    private var isPrinting: Bool = false
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupBluetooth()
    }
    
    private func setupBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .utility))
    }
    
    // MARK: - Public Methods
    func printReceipt(for order: Order) async throws {
        guard let printerPeripheral = printerPeripheral,
              let _ = printerCharacteristic,
              printerPeripheral.state == .connected else {
            throw AppError.printer(.printFailed)
        }
        
        let receiptData = try await generateReceiptData(for: order)
        try await printData(receiptData)
    }
    
    func printDailyReport() async throws {
        guard let printerPeripheral = printerPeripheral,
              let _ = printerCharacteristic,
              printerPeripheral.state == .connected else {
            throw AppError.printer(.printFailed)
        }
        
        let reportData = try await generateDailyReportData()
        try await printData(reportData)
    }
    
    // MARK: - Private Methods
    private func printData(_ data: Data) async throws {
        guard let printerPeripheral = printerPeripheral,
              let printerCharacteristic = printerCharacteristic,
              printerPeripheral.state == .connected else {
            throw AppError.printer(.printFailed)
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Split data into chunks if needed (some printers have MTU limitations)
            let chunkSize = 512 // Adjust based on printer's MTU
            let chunks = stride(from: 0, to: data.count, by: chunkSize).map {
                data[$0..<min($0 + chunkSize, data.count)]
            }
            
            for chunk in chunks {
                try await withCheckedThrowingContinuation { continuation in
                    printerPeripheral.writeValue(Data(chunk), for: printerCharacteristic, type: .withResponse)
                    // Note: In a real implementation, you would need to handle the write response
                    // through CBPeripheralDelegate methods
                    continuation.resume()
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error
            }
            throw error
        }
    }
    
    private func generateReceiptData(for order: Order) async throws -> Data {
        // Implement receipt template generation
        var receiptText = ""
        
        // Header
        receiptText += "CỬA HÀNG XYZ\n"
        receiptText += "Địa chỉ: 123 Đường ABC\n"
        receiptText += "SĐT: 0123456789\n"
        receiptText += "------------------------\n"
        
        // Order Info
        receiptText += "Hóa đơn #\(order.id ?? "")\n"
        receiptText += "Ngày: \(formatDate(order.createdAt))\n"
        receiptText += "------------------------\n"
        
        // Items
        for item in order.items {
            receiptText += "\(item.name)\n"
            receiptText += "\(item.quantity)x \(formatPrice(item.price)) = \(formatPrice(Double(item.quantity) * item.price))\n"
        }
        
        receiptText += "------------------------\n"
        
        // Totals
        receiptText += "Tổng cộng: \(formatPrice(order.totalAmount))\n"
        if let discount = order.discount {
            receiptText += "Giảm giá: \(formatPrice(discount))\n"
        }
        receiptText += "Thanh toán: \(formatPrice(order.totalAmount))\n"
        
        // Footer
        receiptText += "------------------------\n"
        receiptText += "Cảm ơn quý khách!\n"
        receiptText += "------------------------\n\n\n\n" // Add some blank lines for paper cutting
        
        // Convert to printer data
        // Note: This is a simple implementation. In reality, you might need to:
        // 1. Use specific printer commands for formatting
        // 2. Handle different character encodings
        // 3. Add barcode/QR code support
        return receiptText.data(using: .utf8) ?? Data()
    }
    
    private func generateDailyReportData() async throws -> Data {
        // Implement daily report template generation
        var reportText = ""
        
        // Header
        reportText += "BÁO CÁO DOANH THU\n"
        reportText += "Ngày: \(formatDate(Date()))\n"
        reportText += "------------------------\n"
        
        // TODO: Add actual report data
        // This would typically include:
        // - Total sales
        // - Number of orders
        // - Sales by category
        // - Payment methods
        // - etc.
        
        reportText += "------------------------\n"
        reportText += "Kết thúc báo cáo\n"
        reportText += "------------------------\n\n\n\n"
        
        return reportText.data(using: .utf8) ?? Data()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - CBCentralManagerDelegate
extension PrinterService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            Task { @MainActor in
                error = AppError.printer(.bluetoothNotAvailable)
            }
        case .unauthorized:
            Task { @MainActor in
                error = AppError.printer(.bluetoothNotAuthorized)
            }
        default:
            break
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([Printer.printerServiceUUID])
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.error = AppError.printer(.connectionFailed)
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            printerPeripheral = nil
            printerCharacteristic = nil
            self.error = error ?? AppError.printer(.connectionFailed)
        }
    }
}

// MARK: - CBPeripheralDelegate
extension PrinterService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first else { return }
        peripheral.discoverCharacteristics([Printer.printerCharacteristicUUID], for: service)
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first else { return }
        
        Task { @MainActor in
            printerCharacteristic = characteristic
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Task { @MainActor in
                self.error = error
            }
        }
    }
}
