import SwiftUI

struct StaffView: View {
    @ObservedObject private var viewModel: StaffViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    private var shop: Shop?
    
    init(viewModel: StaffViewModel, shop: Shop?) {
        self.viewModel = viewModel
        self.shop = shop
    }
    
    var body: some View {
        Group {
            if let shops = appState.sourceModel.shops, shops.isEmpty {
                noShopView
            } else {
                content
            }
        }
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .navigationTitle("Quản lý nhân viên")
        .sheet(isPresented: $viewModel.showingAddStaffSheet) {
            AddStaffSheet(viewModel: viewModel, staff: viewModel.selectedStaff, shop: shop)
        }
        .alert("Xóa nhân viên", isPresented: $viewModel.showingDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                if let staff = viewModel.selectedStaff {
                    Task {
                        try await viewModel.deleteStaff(staff)
                    }
                }
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa nhân viên này?")
        }
        .onAppear {
            viewModel.startHeaderAnimation()
            viewModel.setupStaffsListener(shopId: shop?.id ?? "")
        }
        .onDisappear {
            viewModel.removeStaffsListener(shopId: shop?.id ?? "")
        }
    }
    
    // MARK: - No Shop View
    private var noShopView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(appState.currentTabThemeColors.textGradient(for: colorScheme))
            
            Text("Chưa có cửa hàng nào")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Bạn cần tạo cửa hàng trước khi quản lý nhân viên")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack {
                Label("Tạo cửa hàng mới", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                        appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
                    }
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
        .padding()
    }
    
    // MARK: - Main Content
    private var content: some View {
        Group {
            if isIphone {
                staffList
            } else {
                HStack(spacing: 0) {
                    // Sidebar with staff list
                    staffList
                        .frame(width: 320)
                        //.background(Color(.systemGroupedBackground))
                    
                    // Detail view
                    if let staff = viewModel.selectedStaff {
                        staffDetail(staff)
                            .frame(maxWidth: .infinity)
                    } else {
                        placeholderView
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // MARK: - Staff List
    private var staffList: some View {
        VStack(spacing: 0) {
            // Header with stats
            headerSection
                .opacity(viewModel.animateHeader ? 1 : 0)
                .offset(y: viewModel.animateHeader ? 0 : -20)
            
            // Search and filter
            if viewModel.showingSearchBar {
                searchAndFilterSection
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            if viewModel.filteredStaff.isEmpty {
                emptyStateView
            } else {
                ScrollView(showsIndicators: false){
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredStaff) { staff in
                            staffCard(staff: staff)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Add staff button for iPhone
            if isIphone && !viewModel.filteredStaff.isEmpty {
                addStaffButton
                    .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        viewModel.toggleSearchBar()
                    } label: {
                        Image(systemName: viewModel.showingSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    
                    if !isIphone {
                        addButton
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: isIphone ? 12 : 16) {
            HStack {
                VStack(alignment: .leading, spacing: isIphone ? 6 : 8) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(isIphone ? .title3 : .title2)
                            .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
                        
                        Text("\(viewModel.filteredStaff.count) nhân viên")
                            .font(isIphone ? .caption : .subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Tổng lương tháng: \(viewModel.formattedTotalMonthlyPayroll)")
                        .font(isIphone ? .subheadline : .headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Decorative divider
            HStack {
                ModernDivider(tabThemeColors: appState.currentTabThemeColors)
                
                Spacer()
            }
        }
        .padding(.horizontal, isIphone ? 16 : 20)
        .padding(.vertical, isIphone ? 12 : 16)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .padding(isIphone ? 12 : 16)
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Tìm kiếm nhân viên...", text: $viewModel.searchText)
                    .textFieldStyle(CustomTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .middleLayer(tabThemeColors: appState.currentTabThemeColors)
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Position filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    filterButton(title: "Tất cả", isSelected: viewModel.selectedPosition == nil) {
                        viewModel.selectPosition(nil)
                    }
                    
                    ForEach(StaffPosition.allCases, id: \.self) { position in
                        filterButton(title: position.displayName, isSelected: viewModel.selectedPosition == position) {
                            viewModel.selectPosition(position)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Filter Button
    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? appState.currentTabThemeColors.primaryColor : Color.systemGray6)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [appState.currentTabThemeColors.primaryColor.opacity(0.8),
                                 appState.currentTabThemeColors.secondaryColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Chưa có nhân viên nào")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Hãy thêm nhân viên đầu tiên cho cửa hàng của bạn")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            addStaffButton
                .padding(.top, 10)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Add Staff Button
    private var addStaffButton: some View {
        Button {
            viewModel.showAddStaffSheet()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Thêm nhân viên mới")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(appState.currentTabThemeColors.gradient(for: colorScheme))
            .foregroundColor(.white)
            .cornerRadius(15)
        }
    }
    
    // MARK: - Add Button
    private var addButton: some View {
        Button {
            viewModel.showAddStaffSheet()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
        }
    }
    
    // MARK: - Placeholder View
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Chọn một nhân viên để xem chi tiết")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Stat Card
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
            Label(title, systemImage: icon)
                .font(isIphone ? .subheadline : .body)
                .foregroundColor(color)
            
            Text(value)
                .font(isIphone ? .title3 : .title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isIphone ? 12 : 16)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .cornerRadius(isIphone ? 10 : 12)
    }
    
    // MARK: - Staff Card
    private func staffCard(staff: Staff) -> some View {
        Button(action: {
            viewModel.selectStaff(staff)
            if isIphone {
                viewModel.showAddStaffSheet(for: staff)
            }
        }) {
            HStack(spacing: isIphone ? 12 : 16) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [appState.currentTabThemeColors.primaryColor.opacity(0.8),
                                     appState.currentTabThemeColors.secondaryColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isIphone ? 45 : 50, height: isIphone ? 45 : 50)
                    .overlay(
                        Text(staff.name.prefix(1).uppercased())
                            .font(isIphone ? .title3 : .title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: isIphone ? 3 : 4) {
                    Text(staff.name)
                        .font(isIphone ? .headline : .title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: isIphone ? 6 : 8) {
                        Text(staff.position.displayName)
                            .font(isIphone ? .caption : .subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(isIphone ? .caption : .subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(staff.workSchedule.keys.count) ngày/tuần")
                            .font(isIphone ? .caption : .subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    Text(staff.formattedEstimatedMonthlySalary)
                        .font(isIphone ? .subheadline : .body)
                        .foregroundColor(appState.currentTabThemeColors.textColor(for: colorScheme))
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Action button
                Menu {
                    Button {
                        viewModel.showAddStaffSheet(for: staff)
                    } label: {
                        Label("Chỉnh sửa", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.showDeleteAlert(for: staff)
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(isIphone ? .title3 : .title2)
                        .foregroundColor(.gray)
                        .frame(width: isIphone ? 40 : 44, height: isIphone ? 40 : 44)
                }
            }
            .padding(isIphone ? 12 : 16)
            .layeredCard(tabThemeColors: appState.currentTabThemeColors)
            .cornerRadius(isIphone ? 12 : 15)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Staff Detail
    private func staffDetail(_ staff: Staff) -> some View {
        ScrollView(showsIndicators: false){
            VStack(spacing: isIphone ? 20 : 24) {
                // Header
                headerDetailSection(staff: staff)
                
                // Stats
                statsSection(staff: staff)
                
                // Work Schedule Summary
                workScheduleSummary(staff: staff)
                
                // Weekly Schedule
                weeklyScheduleView(staff: staff)
                
                // Metadata
                metadataSection(staff: staff)
            }
            .padding()
        }
//        .background(Color(.systemGroupedBackground))
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
    }
    
    // MARK: - Header Detail Section
    private func headerDetailSection(staff: Staff) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: isIphone ? 6 : 8) {
                Text(staff.name)
                    .font(isIphone ? .title2 : .title)
                    .fontWeight(.bold)
                
                Label(staff.position.displayName, systemImage: "person.badge.clock")
                    .font(isIphone ? .subheadline : .headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button {
                    viewModel.showAddStaffSheet(for: staff)
                } label: {
                    Label("Chỉnh sửa", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    viewModel.showDeleteAlert(for: staff)
                } label: {
                    Label("Xóa", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(isIphone ? .title3 : .title2)
                    .foregroundColor(.gray)
            }
        }
        .padding(isIphone ? 16 : 20)
//        .background(Color(.systemBackground))
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .cornerRadius(isIphone ? 12 : 15)
    }
    
    // MARK: - Stats Section
    private func statsSection(staff: Staff) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: isIphone ? 12 : 16) {
            statCard(
                title: "Lương theo giờ",
                value: viewModel.formatCurrency(staff.hourlyRate),
                icon: "dollarsign.circle.fill",
                color: .blue
            )
            
            statCard(
                title: "Lương tháng dự tính",
                value: staff.formattedEstimatedMonthlySalary,
                icon: "chart.bar.fill",
                color: .green
            )
        }
    }
    
    // MARK: - Work Schedule Summary
    private func workScheduleSummary(staff: Staff) -> some View {
        HStack(spacing: isIphone ? 16 : 20) {
            VStack(alignment: .leading, spacing: isIphone ? 4 : 6) {
                Text("Tổng giờ/tuần")
                    .font(isIphone ? .caption : .subheadline)
                    .foregroundColor(.secondary)
                Text(staff.formattedWeeklyHours)
                    .font(isIphone ? .headline : .title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: isIphone ? 4 : 6) {
                Text("Ngày làm việc")
                    .font(isIphone ? .caption : .subheadline)
                    .foregroundColor(.secondary)
                Text("\(staff.workSchedule.keys.count)/7")
                    .font(isIphone ? .headline : .title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: isIphone ? 4 : 6) {
                Text("Lương tháng")
                    .font(isIphone ? .caption : .subheadline)
                    .foregroundColor(.secondary)
                Text(staff.formattedEstimatedMonthlySalary)
                    .font(isIphone ? .headline : .title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(isIphone ? 16 : 20)
//        .background(Color(.systemBackground))
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .cornerRadius(isIphone ? 12 : 15)
    }
    
    // MARK: - Weekly Schedule View
    private func weeklyScheduleView(staff: Staff) -> some View {
        VStack(alignment: .leading, spacing: isIphone ? 12 : 16) {
            Text("Lịch làm việc tuần")
                .font(isIphone ? .headline : .title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: isIphone ? 6 : 8) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    dayScheduleCard(staff: staff, day: day)
                }
            }
        }
        .padding(isIphone ? 16 : 20)
//        .background(Color(.systemBackground))
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .cornerRadius(isIphone ? 12 : 15)
    }
    
    // MARK: - Day Schedule Card
    private func dayScheduleCard(staff: Staff, day: DayOfWeek) -> some View {
        let isWorkingDay = staff.isWorkingDay(day)
        let shifts = staff.getShiftsForDay(day)
        let totalHours = shifts.reduce(0) { $0 + $1.hoursWorked }
        
        return VStack(spacing: isIphone ? 3 : 4) {
            Text(day.shortName)
                .font(isIphone ? .caption2 : .caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            if isWorkingDay {
                Text("\(Int(totalHours))h")
                    .font(isIphone ? .subheadline : .body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let firstShift = shifts.first {
                    Text(firstShift.type.displayName)
                        .font(isIphone ? .caption2 : .caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            } else {
                Text("-")
                    .font(isIphone ? .subheadline : .body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: isIphone ? 50 : 60)
        .frame(maxWidth: .infinity)
        .background(isWorkingDay ? Color.blue.opacity(0.1) : Color.systemGray6)
        .cornerRadius(isIphone ? 6 : 8)
        .overlay(
            RoundedRectangle(cornerRadius: isIphone ? 6 : 8)
                .stroke(isWorkingDay ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Metadata Section
    private func metadataSection(staff: Staff) -> some View {
        VStack(alignment: .leading, spacing: isIphone ? 12 : 16) {
            Text("Thông tin hệ thống")
                .font(isIphone ? .headline : .title2)
                .fontWeight(.semibold)
            
            HStack(spacing: isIphone ? 16 : 20) {
                VStack(alignment: .leading, spacing: isIphone ? 4 : 6) {
                    Text("Ngày tạo")
                        .font(isIphone ? .caption : .subheadline)
                        .foregroundColor(.secondary)
                    Text(formatDate(staff.createdAt))
                        .font(isIphone ? .subheadline : .body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: isIphone ? 4 : 6) {
                    Text("Cập nhật lần cuối")
                        .font(isIphone ? .caption : .subheadline)
                        .foregroundColor(.secondary)
                    Text(formatDate(staff.updatedAt, includeTime: true))
                        .font(isIphone ? .subheadline : .body)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(isIphone ? 16 : 20)
//        .background(Color(.systemBackground))
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .cornerRadius(isIphone ? 12 : 15)
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date, includeTime: Bool = false) -> String {
        let formatter = DateFormatter()
        if includeTime {
            formatter.dateFormat = "dd/MM/yyyy HH:mm"
        } else {
            formatter.dateFormat = "dd/MM/yyyy"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Extensions
extension StaffPosition: CaseIterable {
    static var allCases: [StaffPosition] = [.cashier, .waiter]
}
