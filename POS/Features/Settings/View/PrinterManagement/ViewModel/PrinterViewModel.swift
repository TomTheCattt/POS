//
//  PrinterViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import Foundation
import Combine
import CoreBluetooth

@MainActor
final class PrinterViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var discoveredPrinters: [Printer] = []
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var isConnecting: Bool = false
    @Published private(set) var connectedPrinter: Printer?
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var isBluetoothAuthorized: Bool = false
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Bluetooth Properties
    private var centralManager: CBCentralManager?
    private var printerPeripheral: CBPeripheral?
    private var printerCharacteristic: CBCharacteristic?
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        super.init()
        setupBluetooth()
    }
    
    private func setupBluetooth() {
        // Create central manager on a background queue to avoid main actor issues
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .utility))
    }
    
    // MARK: - Bluetooth Methods
    func checkBluetoothAuthorization() {
        guard let centralManager = centralManager else { return }
        
        switch centralManager.state {
        case .poweredOn:
            isBluetoothAuthorized = true
            bluetoothState = .poweredOn
        case .poweredOff:
            isBluetoothAuthorized = false
            bluetoothState = .poweredOff
            source.handleError(AppError.printer(.bluetoothNotAvailable))
        case .unauthorized:
            isBluetoothAuthorized = false
            bluetoothState = .unauthorized
            source.handleError(AppError.printer(.bluetoothNotAuthorized))
        case .unsupported:
            isBluetoothAuthorized = false
            bluetoothState = .unsupported
            source.handleError(AppError.printer(.bluetoothNotAvailable))
        default:
            isBluetoothAuthorized = false
            bluetoothState = centralManager.state
        }
    }
    
    func startScanning() {
        guard let centralManager = centralManager,
              centralManager.state == .poweredOn else {
            source.handleError(AppError.printer(.bluetoothNotAvailable))
            return
        }
        
        Task { @MainActor in
            isScanning = true
            discoveredPrinters.removeAll()
        }
        
        centralManager.scanForPeripherals(
            withServices: [Printer.printerServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
    
    func stopScanning() {
        centralManager?.stopScan()
        Task { @MainActor in
            isScanning = false
        }
    }
    
    func connect(to printer: Printer) {
        guard let centralManager = centralManager,
              centralManager.state == .poweredOn else {
            source.handleError(AppError.printer(.bluetoothNotAvailable))
            return
        }
        
        Task { @MainActor in
            isConnecting = true
        }
        printerPeripheral = printer.peripheral
        centralManager.connect(printer.peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = printerPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        printerPeripheral = nil
        printerCharacteristic = nil
        Task { @MainActor in
            connectedPrinter = nil
        }
    }
    
    func printData(_ data: Data) {
        guard let characteristic = printerCharacteristic else {
            source.handleError(AppError.printer(.printFailed))
            return
        }
        
        printerPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate
extension PrinterViewModel: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            checkBluetoothAuthorization()
            
            if central.state == .poweredOn {
                print("Bluetooth is powered on")
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let printer = Printer(
            id: peripheral.identifier.uuidString,
            name: peripheral.name ?? "Unknown Printer",
            peripheral: peripheral,
            isConnected: false,
            rssi: RSSI.intValue
        )
        
        Task { @MainActor in
            if !self.discoveredPrinters.contains(where: { $0.id == printer.id }) {
                self.discoveredPrinters.append(printer)
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.isConnecting = false
        }
        peripheral.delegate = self
        peripheral.discoverServices([Printer.printerServiceUUID])
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.isConnecting = false
            self.source.handleError(AppError.printer(.connectionFailed))
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectedPrinter = nil
            self.printerPeripheral = nil
            self.printerCharacteristic = nil
        }
    }
}

// MARK: - CBPeripheralDelegate
extension PrinterViewModel: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first else { return }
        peripheral.discoverCharacteristics([Printer.printerCharacteristicUUID], for: service)
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first else { return }
        
        Task { @MainActor in
            self.printerCharacteristic = characteristic
            if let printer = self.discoveredPrinters.first(where: { $0.peripheral == peripheral }) {
                var updatedPrinter = printer
                updatedPrinter.isConnected = true
                self.connectedPrinter = updatedPrinter
            }
        }
    }
}
