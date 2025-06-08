//
//  HistoryView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var selectedOrder: Order?
    @State private var isSearchFocused = false
    @State private var selectedFilterIndex = 0
    
    private let columns = [
        GridItem(.flexible())
    ]
    
    private let filterOptions = [
        DateRange.today, .yesterday, .thisWeek, .thisMonth
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with animated stats
                    headerSection
                        .padding(.top, 10)
                    
                    // Enhanced search section
                    searchSection
                    
                    // Animated filter tabs
                    filterTabsSection
                    
                    // Orders list with enhanced animations
                    ordersListSection
                }
                .padding(.bottom, 20)
                .background(Color(.systemGray6))
            }
        }
//        .navigationTitle("Lịch sử đơn hàng")
//        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedOrder) { order in
            EnhancedOrderDetailView(order: order, viewModel: viewModel)
        }
        .onAppear {
            appState.sourceModel.setupOrdersListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
        }
        .onDisappear {
            appState.sourceModel.removeOrdersListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Welcome section
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Xin chào! 👋")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("Quản lý đơn hàng của bạn")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Quick action button
                    Button {
                        appState.coordinator.navigateTo(.filter, using: .present, with: .present)
                    }
                           label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Enhanced stats cards
            HStack(spacing: 16) {
                EnhancedStatCard(
                    title: "Tổng đơn",
                    value: "\(viewModel.filteredOrders.count)",
                    subtitle: "/ \(viewModel.orders.count) đơn",
                    icon: "doc.text.fill",
                    gradient: [Color.blue, Color.cyan],
                    iconBackground: Color.blue.opacity(0.1)
                )
                
                EnhancedStatCard(
                    title: "Doanh thu",
                    value: viewModel.formatPrice(viewModel.filteredOrders.reduce(0) { $0 + $1.totalAmount }),
                    subtitle: "hôm nay",
                    icon: "creditcard.fill",
                    gradient: [Color.green, Color.mint],
                    iconBackground: Color.green.opacity(0.1)
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchFocused ? .blue : .secondary)
                        .scaleEffect(isSearchFocused ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isSearchFocused)
                    
                    TextField("Tìm theo mã đơn, tên món...", text: $viewModel.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                isSearchFocused = true
                            }
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .scaleEffect(0.9)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSearchFocused ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                        )
                )
                .animation(.spring(response: 0.3), value: isSearchFocused)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Filter Tabs Section
    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(filterOptions.enumerated()), id: \.offset) { index, range in
                    let isSelected = viewModel.selectedDateRange == range
                    let count = viewModel.orders.filter { range.dateInterval?.contains($0.createdAt) ?? false }.count
                    
                    EnhancedFilterChip(
                        title: range.rawValue,
                        count: count,
                        isSelected: isSelected
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.selectedDateRange = range
                            selectedFilterIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Orders List Section
    private var ordersListSection: some View {
        Group {
            if viewModel.filteredOrders.isEmpty {
                enhancedEmptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(viewModel.filteredOrders.enumerated()), id: \.element.id) { index, order in
                        Button {
                            appState.coordinator.navigateTo(.orderDetail(order), using: .present, with: .present)
                        } label: {
                            appState.coordinator.makeView(for: .orderCard(order))
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(LinearGradient(colors: [.gray, .secondary], startPoint: .top, endPoint: .bottom))
                    
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                }
            }
            
            VStack(spacing: 12) {
                Text("Chưa có đơn hàng nào")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm để xem kết quả")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Action button
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.selectedDateRange = .thisMonth
                    viewModel.searchText = ""
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Đặt lại bộ lọc")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Enhanced Supporting Views

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let iconBackground: Color
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

struct EnhancedFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .opacity(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemBackground)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedOrderCard: View {
    let order: Order
    @ObservedObject var viewModel: HistoryViewModel
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with enhanced styling
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(order.formattedId)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Status indicator
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(viewModel.formatDate(order.createdAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Payment method with enhanced badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: order.paymentMethod == .cash ? "banknote" : "creditcard")
                        .font(.caption)
                    Text(order.paymentMethod.rawValue)
                        .font(.caption)
                }
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                )
                .foregroundColor(.blue)
                
                Spacer()
                
                // Items count badge
                Text("\(order.items.count) món")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            
            Divider()
                .opacity(0.6)
            
            // Price and items preview
            VStack(spacing: 12) {
                HStack {
                    Text("Tổng tiền:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formatPrice(order.totalAmount))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // Items preview with better formatting
                if !order.items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Món đã đặt:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(order.items.prefix(3).map { "\($0.quantity)x \($0.name)" }.joined(separator: " • "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if order.items.count > 3 {
                            Text("và \(order.items.count - 3) món khác...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(isPressed ? 0.15 : 0.08), radius: isPressed ? 20 : 12, x: 0, y: isPressed ? 8 : 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
    }
}

// MARK: - Enhanced Detail Views

struct EnhancedOrderDetailView: View {
    let order: Order
    let viewModel: HistoryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Đơn hàng")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(order.formattedId)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Trạng thái")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Hoàn thành")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(spacing: 12) {
                        DetailRow(title: "Thời gian", value: viewModel.formatDate(order.createdAt), icon: "clock")
                        DetailRow(title: "Thanh toán", value: order.paymentMethod.rawValue, icon: "creditcard")
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                
                // Items section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Danh sách món (\(order.items.count))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(order.items) { item in
                            EnhancedItemRow(item: item, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Total section
                VStack(spacing: 16) {
                    HStack {
                        Text("Tổng cộng")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(viewModel.formatPrice(order.totalAmount))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                )
            }
            .padding(20)
        }
        .background(Color(.systemGray6))
        .navigationTitle("Chi tiết đơn hàng")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Đóng") {
                    dismiss()
                }
                .fontWeight(.medium)
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct EnhancedItemRow: View {
    let item: OrderItem
    let viewModel: HistoryViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Quantity badge
                Text("\(item.quantity)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.blue)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Label(item.temperature.rawValue, systemImage: "thermometer")
                        Label(item.consumption.rawValue, systemImage: "cup.and.saucer")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(viewModel.formatPrice(item.price * Double(item.quantity)))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if let note = item.note, !note.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

struct EnhancedFilterView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var appState: AppState
    
    private let filterOptions = [
        DateRange.today, .yesterday, .thisWeek, .thisMonth
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filterOptions, id: \.self) { range in
                    Button {
                        viewModel.selectedDateRange = range
                        appState.coordinator.dismiss(style: .present)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: range == viewModel.selectedDateRange ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(range == viewModel.selectedDateRange ? .blue : .secondary)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(range.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Lọc theo \(range.rawValue.lowercased())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Chọn khoảng thời gian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        appState.coordinator.dismiss(style: .present)
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}
