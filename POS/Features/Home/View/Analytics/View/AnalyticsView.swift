//
//  AnalyticsView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: AnalyticsViewModel
    
    @State private var selectedTimeFilter: TimeFilter = .week
    @State private var revenueData: [RevenueData] = []
    @State private var isLoading: Bool = false
    @State private var showContent: Bool = false
    @State private var selectedDataPoint: RevenueData?
    @State private var animationProgress: Double = 0.0
    
    // Mock data - replace with your actual data source
    @State private var totalRevenue: Double = 25450.50
    @State private var totalOrders: Int = 342
    @State private var averageOrderValue: Double = 74.35
    @State private var topSellingItem: String = "Cappuccino"
    
    var body: some View {
        ScrollView {
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Phân tích doanh thu")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
            loadAnalyticsData()
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
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        loadAnalyticsData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
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
                        loadAnalyticsData()
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
                                .fill(selectedTimeFilter == filter ? Color.brown : Color.clear)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTimeFilter)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Metrics Cards Section
    private var metricsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Tổng doanh thu",
                value: formatCurrency(totalRevenue),
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                trend: "+12.5%",
                showContent: showContent,
                delay: 0.2
            )
            
            MetricCard(
                title: "Số đơn hàng",
                value: "\(totalOrders)",
                icon: "cart.fill",
                color: .blue,
                trend: "+8.3%",
                showContent: showContent,
                delay: 0.3
            )
            
            MetricCard(
                title: "Đơn hàng trung bình",
                value: formatCurrency(averageOrderValue),
                icon: "chart.bar.fill",
                color: .orange,
                trend: "+3.7%",
                showContent: showContent,
                delay: 0.4
            )
            
            MetricCard(
                title: "Món bán chạy",
                value: topSellingItem,
                icon: "cup.and.saucer.fill",
                color: .brown,
                trend: "156 ly",
                showContent: showContent,
                delay: 0.5
            )
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
            
            if isLoading {
                chartLoadingView
            } else {
                revenueChart
            }
            
            if let selectedData = selectedDataPoint {
                selectedDataView(data: selectedData)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var revenueChart: some View {
        Chart(revenueData) { data in
            let maxX = revenueData.count
            let isSelected = selectedDataPoint?.date == data.date
            let index = revenueData.firstIndex(of: data) ?? 0
            
            // Tính toán progress cho animation từ trái sang phải
            let normalizedIndex = Double(index) / Double(max(maxX - 1, 1))
            let animationDelay = normalizedIndex * 0.5 // Delay tối đa 0.5 giây
            let adjustedProgress = showContent ?
                min(1.0, max(0.0, (animationProgress - animationDelay) / 0.5)) : 0.0

            AreaMark(
                x: .value("Thời gian", data.date),
                y: .value("Doanh thu", data.revenue * adjustedProgress)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.brown.opacity(0.6), .brown.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            .opacity(adjustedProgress > 0 ? 1.0 : 0.0)

            LineMark(
                x: .value("Thời gian", data.date),
                y: .value("Doanh thu", data.revenue * adjustedProgress)
            )
            .foregroundStyle(.brown)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
            .opacity(adjustedProgress > 0 ? 1.0 : 0.0)

            if isSelected {
                PointMark(
                    x: .value("Thời gian", data.date),
                    y: .value("Doanh thu", data.revenue)
                )
                .foregroundStyle(.brown)
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
                    .progressViewStyle(CircularProgressViewStyle(tint: .brown))
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
    
    private func selectedDataView(data: RevenueData) -> some View {
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
                let previousData = findPreviousDataPoint(from: data)
                if let previous = previousData {
                    let percentageChange = ((data.revenue - previous.revenue) / previous.revenue) * 100
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thông tin chi tiết")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InsightRow(
                    icon: "clock.fill",
                    title: "Giờ cao điểm",
                    value: "7:00 - 9:00 AM",
                    detail: "35% tổng doanh thu",
                    showContent: showContent,
                    delay: 0.6
                )
                
                InsightRow(
                    icon: "calendar.badge.plus",
                    title: "Ngày tốt nhất",
                    value: "Thứ 6",
                    detail: "Doanh thu cao nhất tuần",
                    showContent: showContent,
                    delay: 0.7
                )
                
                InsightRow(
                    icon: "person.2.fill",
                    title: "Khách hàng mới",
                    value: "23 người",
                    detail: "Tăng 15% so với tuần trước",
                    showContent: showContent,
                    delay: 0.8
                )
                
                InsightRow(
                    icon: "percent",
                    title: "Tỷ lệ trả lại",
                    value: "2.1%",
                    detail: "Giảm 0.5% so với tháng trước",
                    showContent: showContent,
                    delay: 0.9
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Functions
    private func loadAnalyticsData() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            revenueData = generateMockData()
            isLoading = false
        }
    }
    
    private func refreshData() async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        revenueData = generateMockData()
        isLoading = false
    }
    
    private func findClosestDataPoint(to date: Date) -> RevenueData? {
        return revenueData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private func findPreviousDataPoint(from data: RevenueData) -> RevenueData? {
        guard let index = revenueData.firstIndex(where: { $0.id == data.id }),
              index > 0 else { return nil }
        return revenueData[index - 1]
    }
    
    private func generateMockData() -> [RevenueData] {
        let calendar = Calendar.current
        let now = Date()
        var data: [RevenueData] = []
        
        switch selectedTimeFilter {
        case .day:
            for hour in 0..<24 {
                if let date = calendar.date(byAdding: .hour, value: -hour, to: now) {
                    let revenue = Double.random(in: 50...300)
                    data.append(RevenueData(date: date, revenue: revenue))
                }
            }
        case .week:
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                    let revenue = Double.random(in: 1000...4000)
                    data.append(RevenueData(date: date, revenue: revenue))
                }
            }
        case .month:
            for week in 0..<4 {
                if let date = calendar.date(byAdding: .weekOfYear, value: -week, to: now) {
                    let revenue = Double.random(in: 15000...25000)
                    data.append(RevenueData(date: date, revenue: revenue))
                }
            }
        }
        
        return data.reversed()
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .opacity(showCard ? 1 : 0)
        .offset(y: showCard ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
                showCard = true
            }
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let showContent: Bool
    let delay: Double
    
    @State private var showRow = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.brown)
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

// MARK: - Data Models
struct RevenueData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let revenue: Double
}


