//
//  PrinterView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI
import CoreBluetooth

struct PrinterView: View {
    @ObservedObject var viewModel: PrinterViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if !isIphone {
                Text("Kết nối máy in")
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            // Content
            if viewModel.isBluetoothAuthorized {
                mainContent
            } else {
                bluetoothPermissionView
            }
        }
        .frame(maxHeight: .infinity)
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .onAppear {
            viewModel.checkBluetoothAuthorization()
            if viewModel.isBluetoothAuthorized {
                viewModel.startScanning()
            }
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
    
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Bluetooth Status
                BluetoothStatusView(viewModel: viewModel)
                
                // Printer List
                if viewModel.isScanning {
                    ProgressView("Đang tìm kiếm máy in...")
                        .padding()
                } else if viewModel.discoveredPrinters.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Không tìm thấy máy in")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            viewModel.startScanning()
                        } label: {
                            Label("Tìm kiếm lại", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.discoveredPrinters) { printer in
                            PrinterCard(
                                printer: printer,
                                isConnected: viewModel.connectedPrinter?.id == printer.id,
                                onConnect: {
                                    if viewModel.connectedPrinter?.id == printer.id {
                                        viewModel.disconnect()
                                    } else {
                                        viewModel.connect(to: printer)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var bluetoothPermissionView: some View {
        VStack(spacing: 20) {
            BluetoothLogo(color: .secondary, size: 60)
//                .font(.system(size: 60))
//                .foregroundColor(.secondary)
            
            Text("Cần quyền truy cập Bluetooth")
                .font(.title2)
                .bold()
            
            Text(getBluetoothStateMessage())
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack {
                Label("Mở Cài đặt", systemImage: "gear")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 20)
                    .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                        openSettings()
                    }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
//            Button {
//                openSettings()
//            } label: {
//                Label("Mở Cài đặt", systemImage: "gear")
//                    .frame(maxWidth: .infinity)
//            }
//            .buttonStyle(.borderedProminent)
//            .padding(.horizontal, 40)
//            .padding(.top, 20)
        }
        .padding()
    }
    
    private func getBluetoothStateMessage() -> String {
        switch viewModel.bluetoothState {
        case .poweredOff:
            return "Bluetooth đang tắt. Vui lòng bật Bluetooth trong Cài đặt để sử dụng tính năng này."
        case .unauthorized:
            return "Ứng dụng chưa được cấp quyền sử dụng Bluetooth. Vui lòng cấp quyền trong Cài đặt."
        case .unsupported:
            return "Thiết bị của bạn không hỗ trợ Bluetooth."
        default:
            return "Không thể truy cập Bluetooth. Vui lòng kiểm tra lại cài đặt."
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct BluetoothLogo: View {
    var color: Color
    var size: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let h = size.height
            let y1 = h * 0.05
            let y2 = h * 0.25
            
            var path = Path()
            path.move(to: CGPoint(x: y2, y: y2))
            path.addLine(to: CGPoint(x: h - y2, y: h - y2))
            path.addLine(to: CGPoint(x: h / 2, y: h - y1))
            path.addLine(to: CGPoint(x: h / 2, y: y1))
            path.addLine(to: CGPoint(x: h - y2, y: y2))
            path.addLine(to: CGPoint(x: y2, y: h - y2))
            
            context.stroke(
                path,
                with: .color(color),
                lineWidth: 2
            )
        }
        .frame(width: size, height: size)
        .background(Color.clear)
    }
}

// MARK: - Bluetooth Status View
private struct BluetoothStatusView: View {
    @ObservedObject var viewModel: PrinterViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            BluetoothLogo(color: viewModel.connectedPrinter != nil ? .green : .secondary, size: 60)
            
            VStack(alignment: .leading) {
                Text(viewModel.connectedPrinter?.name ?? "Chưa kết nối")
                    .font(.headline)
                
                if let _ = viewModel.connectedPrinter {
                    Text("Đã kết nối")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("Đang tìm kiếm máy in...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if viewModel.isScanning {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    viewModel.startScanning()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Printer Card
private struct PrinterCard: View {
    let printer: Printer
    let isConnected: Bool
    let onConnect: () -> Void
    
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(printer.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "wifi")
                        .font(.caption)
                    Text("\(printer.rssi) dBm")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                onConnect()
            } label: {
                Text(isConnected ? "Ngắt kết nối" : "Kết nối")
                    .frame(width: 100)
            }
            .buttonStyle(.bordered)
            .tint(isConnected ? .red : appState.currentTabThemeColors.primaryColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

//#Preview {
//    PrinterView(viewModel: PrinterViewModel(environment: AppEnvironment()), coordinator: AppCoordinator())
//}
