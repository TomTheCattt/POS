//
//  revenueRecordView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI
import Charts

struct RevenueRecordView: View {
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: RevenueRecordViewModel
    
    @State private var selectedTimeFilter: TimeFilter = .week
    @State private var selectedDataPoint: RevenueRecord?
    @State private var showContent: Bool = false
    @State private var animationProgress: Double = 0.0
    @Environment(\.colorScheme) private var colorScheme
    
    private let shop: Shop?
    
    init(viewModel: RevenueRecordViewModel, shop: Shop?) {
        self.viewModel = viewModel
        self.shop = shop
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header with Time Filter
                headerSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)
                
                // Key Metrics Cards
                metricsCardsSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // Revenue Chart
                revenueChartSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // Additional Insights
                insightsSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .navigationTitle("Phân tích doanh thu")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
            viewModel.loadData(for: selectedTimeFilter)
        }
        .refreshable {
            await refreshData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tổng quan doanh thu")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        appState.sourceModel.currentThemeColors.revenue.primaryColor
                    )
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        viewModel.loadData(for: selectedTimeFilter)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                }
            }
            
            // Time Filter Picker
            timeFilterPicker
        }
    }
    
    private var timeFilterPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTimeFilter = filter
                        viewModel.loadData(for: filter)
                    }
                }) {
                    Text(filter.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeFilter == filter ? .white : .secondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeFilter == filter ? appState.sourceModel.currentThemeColors.revenue.primaryColor : Color.clear)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTimeFilter)
                        )
                }
            }
        }
        .padding(4)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
    
    // MARK: - Metrics Cards Section
    private var metricsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Tổng doanh thu",
                value: formatCurrency(viewModel.totalRevenue),
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                trend: "+\(String(format: "%.1f", calculateRevenueGrowth()))%",
                showContent: showContent,
                delay: 0.2
            )
            
            MetricCard(
                title: "Số đơn hàng",
                value: "\(viewModel.totalOrders)",
                icon: "cart.fill",
                color: .blue,
                trend: "+\(String(format: "%.1f", calculateOrdersGrowth()))%",
                showContent: showContent,
                delay: 0.3
            )
            
            MetricCard(
                title: "Đơn hàng trung bình",
                value: formatCurrency(viewModel.averageOrderValue),
                icon: "chart.bar.fill",
                color: .orange,
                trend: "+\(String(format: "%.1f", calculateAverageOrderGrowth()))%",
                showContent: showContent,
                delay: 0.4
            )
            
            if let topItem = viewModel.topSellingItem {
                MetricCard(
                    title: "Món bán chạy",
                    value: topItem.name,
                    icon: "cup.and.saucer.fill",
                    color: appState.sourceModel.currentThemeColors.revenue.primaryColor,
                    trend: "\(topItem.quantity) món",
                    showContent: showContent,
                    delay: 0.5
                )
            }
        }
    }
    
    // MARK: - Revenue Chart Section
    private var revenueChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Biểu đồ doanh thu")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(selectedTimeFilter.chartDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            
            if viewModel.isLoading {
                chartLoadingView
            } else if viewModel.revenueRecords.isEmpty {
                emptyChartView
            } else {
                revenueChart
            }
            
            if let selectedData = selectedDataPoint {
                selectedDataView(data: selectedData)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(20)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
    
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Chưa có dữ liệu")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Hãy tạo đơn hàng để xem biểu đồ doanh thu")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .transition(.opacity.combined(with: .scale))
    }
    
    private var revenueChart: some View {
        Chart(viewModel.revenueRecords) { record in
            let maxX = viewModel.revenueRecords.count
            let isSelected = selectedDataPoint?.id == record.id
            let index = viewModel.revenueRecords.firstIndex(of: record) ?? 0
            
            // Tính toán progress cho animation từ trái sang phải
            let normalizedIndex = Double(index) / Double(max(maxX - 1, 1))
            let animationDelay = normalizedIndex * 0.5 // Delay tối đa 0.5 giây
            let adjustedProgress = showContent ?
                min(1.0, max(0.0, (animationProgress - animationDelay) / 0.5)) : 0.0

            AreaMark(
                x: .value("Thời gian", record.date),
                y: .value("Doanh thu", record.revenue * adjustedProgress)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [appState.sourceModel.currentThemeColors.revenue.primaryColor.opacity(0.6), appState.sourceModel.currentThemeColors.revenue.primaryColor.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            .opacity(adjustedProgress > 0 ? 1.0 : 0.0)

            LineMark(
                x: .value("Thời gian", record.date),
                y: .value("Doanh thu", record.revenue * adjustedProgress)
            )
            .foregroundStyle(appState.sourceModel.currentThemeColors.revenue.primaryColor)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
            .opacity(adjustedProgress > 0 ? 1.0 : 0.0)

            if isSelected {
                PointMark(
                    x: .value("Thời gian", record.date),
                    y: .value("Doanh thu", record.revenue)
                )
                .foregroundStyle(appState.sourceModel.currentThemeColors.revenue.primaryColor)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: selectedTimeFilter.axisStride)) { value in
                AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                AxisTick().foregroundStyle(Color.gray.opacity(0.6))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisLabel(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                AxisTick().foregroundStyle(Color.gray.opacity(0.6))
                AxisValueLabel {
                    if let revenue = value.as(Double.self) {
                        Text(formatCurrencyShort(revenue))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 200)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let currentX = value.location.x
                                if let date: Date = proxy.value(atX: currentX) {
                                    if let closest = findClosestDataPoint(to: date) {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                            selectedDataPoint = closest
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedDataPoint = nil
                                }
                            }
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
        .onDisappear {
            animationProgress = 0.0
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
    
    private var chartLoadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: appState.sourceModel.currentThemeColors.revenue.primaryColor))
                    .scaleEffect(1.2)
                
                Text("Đang tải dữ liệu...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(height: 200)
        .transition(.opacity.combined(with: .scale))
    }
    
    private func selectedDataView(data: RevenueRecord) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatAxisLabel(data.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(data.revenue))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .transition(.scale.combined(with: .opacity))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let previousData = findPreviousDataPoint(from: data) {
                    let percentageChange = ((data.revenue - previousData.revenue) / previousData.revenue) * 100
                    HStack(spacing: 4) {
                        Image(systemName: percentageChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(String(format: "%.1f%%", abs(percentageChange)))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(percentageChange >= 0 ? .green : .red)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding()
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thông tin chi tiết")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let peakHour = viewModel.peakHours.first {
                    InsightRow(
                        icon: "clock.fill",
                        title: "Giờ cao điểm",
                        value: "\(peakHour.hour):00",
                        detail: "\(String(format: "%.1f", peakHour.percentage))% tổng doanh thu",
                        showContent: showContent,
                        delay: 0.6
                    )
                }
                
                if let bestDay = viewModel.bestDayOfWeek {
                    let weekdays = ["Chủ nhật", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"]
                    InsightRow(
                        icon: "calendar.badge.plus",
                        title: "Ngày tốt nhất",
                        value: weekdays[bestDay.day % 7],
                        detail: "\(String(format: "%.1f", bestDay.percentage))% tổng doanh thu",
                        showContent: showContent,
                        delay: 0.7
                    )
                }
                
                InsightRow(
                    icon: "person.2.fill",
                    title: "Khách hàng mới",
                    value: "\(viewModel.newCustomers) người",
                    detail: "Tỷ lệ quay lại \(String(format: "%.1f", viewModel.returnRate))%",
                    showContent: showContent,
                    delay: 0.8
                )
                
                if let topPayment = viewModel.paymentMethodStats.first {
                    InsightRow(
                        icon: "creditcard.fill",
                        title: "Thanh toán phổ biến",
                        value: topPayment.method.rawValue,
                        detail: "\(String(format: "%.1f", topPayment.percentage))% đơn hàng",
                        showContent: showContent,
                        delay: 0.9
                    )
                }
            }
        }
        .padding(20)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
    
    // MARK: - Helper Functions
    private func refreshData() async {
        viewModel.loadData(for: selectedTimeFilter)
    }
    
    private func findClosestDataPoint(to date: Date) -> RevenueRecord? {
        return viewModel.revenueRecords.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private func findPreviousDataPoint(from data: RevenueRecord) -> RevenueRecord? {
        guard let index = viewModel.revenueRecords.firstIndex(where: { $0.id == data.id }),
              index > 0 else { return nil }
        return viewModel.revenueRecords[index - 1]
    }
    
    private func formatAxisLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedTimeFilter {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "dd/MM"
        }
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₫0"
    }
    
    private func formatCurrencyShort(_ amount: Double) -> String {
        if amount >= 1000000 {
            return String(format: "%.1fM₫", amount / 1000000)
        } else if amount >= 1000 {
            return String(format: "%.0fK₫", amount / 1000)
        } else {
            return String(format: "%.0f₫", amount)
        }
    }
    
    private func calculateRevenueGrowth() -> Double {
        // Tính tỷ lệ tăng trưởng doanh thu
        guard viewModel.revenueRecords.count >= 2 else { return 0 }
        let sortedData = viewModel.revenueRecords.sorted(by: { $0.date < $1.date })
        let previousRevenue = sortedData.first?.revenue ?? 0
        let currentRevenue = sortedData.last?.revenue ?? 0
        guard previousRevenue > 0 else { return 0 }
        return ((currentRevenue - previousRevenue) / previousRevenue) * 100
    }
    
    private func calculateOrdersGrowth() -> Double {
        guard viewModel.revenueRecords.count >= 2 else { return 0 }
        let sortedData = viewModel.revenueRecords.sorted(by: { $0.date < $1.date })
        let previousOrders = Double(sortedData.first?.totalOrders ?? 0)
        let currentOrders = Double(sortedData.last?.totalOrders ?? 0)
        guard previousOrders > 0 else { return 0 }
        return ((currentOrders - previousOrders) / previousOrders) * 100
    }
    
    private func calculateAverageOrderGrowth() -> Double {
        guard viewModel.revenueRecords.count >= 2 else { return 0 }
        let sortedData = viewModel.revenueRecords.sorted(by: { $0.date < $1.date })
        let previousAvg = sortedData.first?.averageOrderValue ?? 0
        let currentAvg = sortedData.last?.averageOrderValue ?? 0
        guard previousAvg > 0 else { return 0 }
        return ((currentAvg - previousAvg) / previousAvg) * 100
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    let showContent: Bool
    let delay: Double
    
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showCard = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(trend)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let showContent: Bool
    let delay: Double
    
    @EnvironmentObject private var appState: AppState
    @State private var showRow = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(appState.sourceModel.currentThemeColors.revenue.primaryColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .opacity(showRow ? 1 : 0)
        .offset(x: showRow ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
                showRow = true
            }
        }
    }
}


