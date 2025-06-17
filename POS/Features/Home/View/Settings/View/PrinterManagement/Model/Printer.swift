import Foundation
import CoreBluetooth

struct Printer: Identifiable {
    let id: String
    let name: String
    let peripheral: CBPeripheral
    var isConnected: Bool
    var rssi: Int
    
    // MARK: - Bluetooth Services & Characteristics
    static let printerServiceUUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    static let printerCharacteristicUUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
}

// MARK: - AppError Extension
extension AppError {
    enum PrinterError: LocalizedError {
        case bluetoothNotAvailable
        case bluetoothNotAuthorized
        case connectionFailed
        case printFailed
        
        var errorDescription: String? {
            switch self {
            case .bluetoothNotAvailable:
                return "Bluetooth không khả dụng"
            case .bluetoothNotAuthorized:
                return "Ứng dụng chưa được cấp quyền sử dụng Bluetooth"
            case .connectionFailed:
                return "Không thể kết nối với máy in"
            case .printFailed:
                return "Không thể in tài liệu"
            }
        }
    }
} 
