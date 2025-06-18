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
    @State private var showContent = false
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme
    
    private let columns = [
        GridItem(.flexible())
    ]
    
    private let filterOptions = [
        DateRange.today, .yesterday, .thisWeek, .thisMonth
    ]
    
    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 20) {
                // Header with animated stats
                headerSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)
                
                // Enhanced search section
                searchSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // Animated filter tabs
                filterTabsSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // Orders list with enhanced animations
                ordersListSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
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
                        Text("Lịch sử đơn hàng")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                appState.currentTabThemeColors.primaryColor
                            )
                    }
                    Spacer()
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
                    subtitle: viewModel.selectedDateRange.rawValue,
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
                .middleLayer(tabThemeColors: appState.currentTabThemeColors)
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
                    filterChip(title: range.rawValue, count: count)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .layeredSelectionButton(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 16, isSelected: isSelected, namespace: animation, geometryID: "selected_date_range") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedDateRange = range
                                selectedFilterIndex = index
                            }
                        }
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Orders List Section
    private var ordersListSection: some View {
        Group {
            ScrollView(showsIndicators: false) {
                if viewModel.filteredOrders.isEmpty {
                    enhancedEmptyStateView
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(viewModel.filteredOrders.enumerated()), id: \.element.id) { index, order in
                            Button {
                                appState.coordinator.navigateTo(.orderDetail(order), using: .present, with: .present)
                            } label: {
                                orderCard(order)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
    
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(appState.currentTabThemeColors.gradient(for: colorScheme).opacity(0.5))
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(LinearGradient(colors: [.gray, .secondary], startPoint: .top, endPoint: .bottom))
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
                .background(appState.currentTabThemeColors.primaryColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func filterChip(title: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
            
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.medium)
                .opacity(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func orderCard(_ order: Order) -> some View {
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
                        .fill(appState.currentTabThemeColors.primaryColor.opacity(0.3))
                )
                .foregroundColor(.primary)
                
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
                            appState.currentTabThemeColors.gradient(for: colorScheme)
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
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
    }
}

// MARK: - Enhanced Supporting Views

struct EnhancedStatCard: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let iconBackground: Color
    @Environment(\.colorScheme) var colorScheme
    
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
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
}

// MARK: - Enhanced Detail Views

struct EnhancedOrderDetailView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    let order: Order
    
    var body: some View {
        ScrollView(showsIndicators: false) {
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
                .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
                
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
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                    }
                }
                .padding(20)
                .layeredCard(tabThemeColors: appState.currentTabThemeColors)
            }
            .padding(20)
        }
        .background(Color(.systemGray6))
        .navigationTitle("Chi tiết đơn hàng")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Đóng") {
                    appState.coordinator.dismiss()
                }
                .fontWeight(.medium)
            }
        }
    }
}

struct DetailRow: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(appState.currentTabThemeColors.primaryColor)
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
    @EnvironmentObject private var appState: AppState
    let item: OrderItem
    let viewModel: HistoryViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Quantity badge
                Text("\(item.quantity)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(appState.currentTabThemeColors.primaryColor)
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
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
}
