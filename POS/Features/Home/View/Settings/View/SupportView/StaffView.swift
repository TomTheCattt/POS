import SwiftUI

struct StaffView: View {
    @ObservedObject var viewModel: StaffViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var showingAddStaffSheet = false
    @State private var selectedStaff: Staff?
    @State private var showingSearchBar = false
    @State private var searchText = ""
    @State private var selectedPosition: StaffPosition?
    @State private var showingDeleteAlert = false
    @State private var animateHeader = false
    
    private let isIpad = UIDevice.current.userInterfaceIdiom == .pad
    
    var filteredStaff: [Staff] {
        var result = viewModel.staffList
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let position = selectedPosition {
            result = result.filter { $0.position == position }
        }
        
        return result
    }
    
    var totalMonthlyPayroll: Double {
        filteredStaff.reduce(0) { $0 + $1.monthlyEarnings }
    }
    
    var body: some View {
        Group {
            if let shops = appState.sourceModel.shops, shops.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Chưa có cửa hàng nào")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Bạn cần tạo cửa hàng trước khi quản lý nhân viên")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button {
                        appState.coordinator.navigateTo(.addShop, using: .present, with: .present)
                    } label: {
                        Label("Tạo cửa hàng mới", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                .padding()
            } else {
                content
            }
        }
        .navigationTitle("Quản lý nhân viên")
        .sheet(isPresented: $showingAddStaffSheet) {
            AddStaffSheet(viewModel: viewModel, staff: selectedStaff)
        }
        .alert("Xóa nhân viên", isPresented: $showingDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                if let staff = selectedStaff {
                    Task {
                        try await viewModel.deleteStaff(staff)
                    }
                }
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa nhân viên này?")
        }
    }
    
    private var content: some View {
        Group {
            if isIpad {
                HStack(spacing: 0) {
                    // Sidebar with staff list
                    staffList
                        .frame(width: 320)
                        .background(Color(.systemGroupedBackground))
                    
                    // Detail view
                    if let staff = selectedStaff {
                        staffDetail(staff)
                            .frame(maxWidth: .infinity)
                    } else {
                        placeholderView
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                staffList
            }
        }
    }
    
    private var staffList: some View {
        VStack(spacing: 0) {
            // Header with stats
            headerSection
                .opacity(animateHeader ? 1 : 0)
                .offset(y: animateHeader ? 0 : -20)
            
            // Search and filter
            if showingSearchBar {
                searchAndFilterSection
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            if filteredStaff.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredStaff) { staff in
                            StaffCard(staff: staff) {
                                selectedStaff = staff
                                if !isIpad {
                                    showingAddStaffSheet = true
                                }
                            } onDelete: {
                                selectedStaff = staff
                                showingDeleteAlert = true
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Add staff button for iPhone
            if !isIpad {
                addStaffButton
                    .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingSearchBar.toggle()
                        }
                    } label: {
                        Image(systemName: showingSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    
                    if isIpad {
                        addButton
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            appState.sourceModel.setupStaffsListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
        }
        .onDisappear {
            appState.sourceModel.removeStaffsListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("\(filteredStaff.count) nhân viên")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Tổng lương tháng: \(formatCurrency(totalMonthlyPayroll))")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Decorative divider
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .frame(maxWidth: 100)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding()
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Tìm kiếm nhân viên...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Position filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    filterButton(title: "Tất cả", isSelected: selectedPosition == nil) {
                        selectedPosition = nil
                    }
                    
                    ForEach(StaffPosition.allCases, id: \.self) { position in
                        filterButton(title: position.displayName, isSelected: selectedPosition == position) {
                            selectedPosition = position
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
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
    
    private var addStaffButton: some View {
        Button {
            selectedStaff = nil
            showingAddStaffSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Thêm nhân viên mới")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
        }
    }
    
    private var addButton: some View {
        Button {
            selectedStaff = nil
            showingAddStaffSheet = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
    
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
    
    private func staffDetail(_ staff: Staff) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(staff.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Label(staff.position.displayName, systemImage: "person.badge.clock")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            showingAddStaffSheet = true
                        } label: {
                            Label("Chỉnh sửa", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    statCard(
                        title: "Lương theo giờ",
                        value: formatCurrency(staff.hourlyRate),
                        icon: "dollarsign.circle.fill",
                        color: .blue
                    )
                    
                    statCard(
                        title: "Lương tháng này",
                        value: staff.formattedMonthlyEarnings,
                        icon: "chart.bar.fill",
                        color: .green
                    )
                }
                
                // Shifts
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ca làm việc gần đây")
                        .font(.headline)
                    
                    if staff.shifts.isEmpty {
                        Text("Chưa có ca làm việc nào")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(staff.shifts) { shift in
                            ShiftCard(shift: shift)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedNumber)đ"
    }
}

struct StaffCard: View {
    let staff: Staff
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(staff.name.prefix(1).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(staff.name)
                        .font(.headline)
                    
                    HStack {
                        Text(staff.position.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(staff.formattedMonthlyEarnings)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Action button
                Menu {
                    Button {
                        onTap()
                    } label: {
                        Label("Chỉnh sửa", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShiftCard: View {
    let shift: WorkShift
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(shift.type.displayName, systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(Int(shift.hoursWorked)) giờ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bắt đầu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDate(shift.startTime))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Kết thúc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDate(shift.endTime))
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Extensions
extension StaffPosition: CaseIterable {
    static var allCases: [StaffPosition] = [.cashier, .waiter]
}
