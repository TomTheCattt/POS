import SwiftUI

struct AddStaffSheet: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: StaffViewModel
    @FocusState private var focusedField: Field?
    @Environment(\.colorScheme) private var colorScheme
    
    private let staff: Staff?
    private let shop: Shop?
    
    init(viewModel: StaffViewModel, staff: Staff?, shop: Shop?) {
        self.viewModel = viewModel
        self.staff = staff
        self.shop = shop
    }
    
    private var isEditing: Bool { staff != nil }
    
    enum Field {
        case name, hourlyRate
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView(showsIndicators: false){
                    VStack(spacing: isIphone ? 24 : 32) {
                        // Header Section
                        headerSection
                        
                        // Form Section
                        VStack(spacing: isIphone ? 24 : 32) {
                            // Basic Info Section
                            basicInfoSection
                            
                            // Salary Section
                            salarySection
                            
                            // Work Schedule Section
                            workScheduleSection
                        }
                        .padding(.horizontal, isIphone ? 16 : 32)
                        
                        // Validation Errors
                        if !viewModel.getValidationErrors().isEmpty {
                            validationErrorsView
                        }
                        
                        // Action Button
                        actionButton
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            appState.coordinator.dismiss(style: .present)
                        } label: {
                            Text("Hủy")
                                .font(isIphone ? .body : .title3)
                                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
                        }
                    }
                }
                .onAppear {
                    if let staff = staff {
                        viewModel.loadStaffData(staff)
                    }
                }
                .onChange(of: viewModel.name) { _ in
                    viewModel.clearValidationErrors()
                }
                .onChange(of: viewModel.hourlyRate) { _ in
                    viewModel.clearValidationErrors()
                }
                .onChange(of: viewModel.position) { _ in
                    viewModel.clearValidationErrors()
                }
                .onChange(of: viewModel.workingDays) { _ in
                    viewModel.clearValidationErrors()
                }
                .onChange(of: viewModel.selectedShifts) { _ in
                    viewModel.clearValidationErrors()
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .interactiveDismissDisabled(viewModel.isLoading)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: isIphone ? 16 : 24) {
            Image(systemName: isEditing ? "person.fill.viewfinder" : "person.fill.badge.plus")
                .font(.system(size: isIphone ? 60 : 80))
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
            
            Text(isEditing ? "Chỉnh sửa nhân viên" : "Thêm nhân viên mới")
                .font(isIphone ? .title2 : .largeTitle)
                .fontWeight(.bold)
            
            Text(isEditing ? "Cập nhật thông tin nhân viên" : "Điền thông tin để thêm nhân viên mới")
                .font(isIphone ? .body : .title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, isIphone ? 20 : 32)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        formSection(title: "Thông tin cơ bản", systemImage: "person.text.rectangle.fill") {
            VStack(spacing: isIphone ? 16 : 24) {
                // Name
                VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                    Label("Tên nhân viên", systemImage: "person.fill")
                        .font(isIphone ? .subheadline : .title3)
                        .foregroundColor(.secondary)
                    
                    TextField("Nhập tên nhân viên", text: $viewModel.name)
                        .textFieldStyle(CustomTextFieldStyle())
                        .font(isIphone ? .body : .title2)
                        .padding(isIphone ? 12 : 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(isIphone ? 12 : 16)
                        .focused($focusedField, equals: .name)
                }
                
                // Position
                VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                    Label("Vị trí", systemImage: "person.badge.clock.fill")
                        .font(isIphone ? .subheadline : .title3)
                        .foregroundColor(.secondary)
                    
                    Picker("Vị trí", selection: $viewModel.position) {
                        ForEach(StaffPosition.allCases, id: \.self) { position in
                            Text(position.displayName)
                                .font(isIphone ? .body : .title3)
                                .tag(position)
                        }
                    }
                    .pickerStyle(.segmented)
                    .scaleEffect(isIphone ? 1.0 : 1.2)
                }
            }
        }
    }
    
    // MARK: - Salary Section
    private var salarySection: some View {
        formSection(title: "Thông tin lương", systemImage: "dollarsign.circle.fill") {
            VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                Label("Lương theo giờ", systemImage: "creditcard.fill")
                    .font(isIphone ? .subheadline : .title3)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(appState.currentTabThemeColors.primaryColor)
                        .font(isIphone ? .body : .title2)
                    TextField("0", text: $viewModel.hourlyRate)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomTextFieldStyle())
                        .font(isIphone ? .body : .title2)
                        .focused($focusedField, equals: .hourlyRate)
                    
                    Text("VNĐ/giờ")
                        .font(isIphone ? .subheadline : .title3)
                        .foregroundColor(.secondary)
                }
                .padding(isIphone ? 12 : 16)
                .background(Color.systemGray6)
                .cornerRadius(isIphone ? 12 : 16)
                
                if let rate = Double(viewModel.hourlyRate), rate > 0 {
                    Text("≈ \(formatCurrency(rate))/giờ")
                        .font(isIphone ? .subheadline : .title3)
                        .foregroundColor(.secondary)
                        .padding(.top, isIphone ? 4 : 8)
                }
            }
        }
    }
    
    // MARK: - Work Schedule Section
    private var workScheduleSection: some View {
        formSection(title: "Ca làm việc", systemImage: "clock.badge.checkmark.fill") {
            VStack(spacing: isIphone ? 16 : 24) {
                // Working Days Horizontal List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isIphone ? 12 : 16) {
                        ForEach(DayOfWeek.allCases, id: \.self) { day in
                            dayButton(for: day)
                        }
                    }
                    .padding(.horizontal, isIphone ? 16 : 20)
                }
                
                // Selected Day Work Schedule
                if let selectedDay = viewModel.expandedDay {
                    selectedDayWorkSchedule(for: selectedDay)
                }
                
                // Summary
                if !viewModel.workingDays.isEmpty {
                    workScheduleSummary
                }
            }
        }
    }
    
    // MARK: - Day Button
    private func dayButton(for day: DayOfWeek) -> some View {
        let isSelected = viewModel.expandedDay == day
        let hasWorkSchedule = viewModel.workingDays.contains(day)
        
        return Button(action: {
            viewModel.toggleExpandedDay(day)
        }) {
            VStack(spacing: isIphone ? 8 : 12) {
                Text(day.rawValue)
                    .font(isIphone ? .headline : .title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if hasWorkSchedule {
                    let selectedShiftsForDay = viewModel.getSelectedShiftsForDay(day)
                    let totalHours = selectedShiftsForDay.reduce(0) { $0 + $1.hoursWorked }
                    Text("\(Int(totalHours))h")
                        .font(isIphone ? .subheadline : .title3)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(width: isIphone ? 80 : 100)
            .padding(.vertical, isIphone ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: isIphone ? 12 : 16)
                    .fill(isSelected ? appState.currentTabThemeColors.primaryColor : Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Selected Day Work Schedule
    private func selectedDayWorkSchedule(for day: DayOfWeek) -> some View {
        VStack(spacing: isIphone ? 16 : 24) {
            // Work Shift Type Picker
            Picker("Loại ca làm việc", selection: Binding(
                get: { viewModel.selectedWorkShiftTypes[day] ?? .fullTime },
                set: { shiftType in
                    viewModel.updateWorkShiftTypeForDay(day, shiftType: shiftType)
                }
            )) {
                ForEach(WorkShiftType.allCases, id: \.self) { type in
                    Text(type.displayName)
                        .font(isIphone ? .body : .title3)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .scaleEffect(isIphone ? 1.0 : 1.1)
            
            // Shift Selection
            VStack(alignment: .leading, spacing: isIphone ? 12 : 16) {
                Text("Chọn ca làm việc:")
                    .font(isIphone ? .subheadline : .title3)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isIphone ? 12 : 16) {
                        ForEach(viewModel.workSchedule[day] ?? [], id: \.id) { shift in
                            shiftCard(shift: shift, day: day)
                        }
                    }
                    .padding(isIphone ? 16 : 20)
                }
            }
        }
        .padding(isIphone ? 16 : 20)
        .background(Color(.systemBackground))
        .cornerRadius(isIphone ? 12 : 16)
    }
    
    // MARK: - Shift Card
    private func shiftCard(shift: WorkShift, day: DayOfWeek) -> some View {
        let isSelected = viewModel.isShiftSelected(shift, day: day)
        
        return Button(action: {
            viewModel.toggleShiftSelection(shift, day: day)
        }) {
            VStack(spacing: isIphone ? 8 : 12) {
                Text("Ca \(viewModel.workSchedule[day]?.firstIndex(of: shift)?.advanced(by: 1) ?? 1)")
                    .font(isIphone ? .caption : .title3)
                    .foregroundColor(.secondary)
                
                Text(shift.timeRangeString)
                    .font(isIphone ? .headline : .title2)
                    .foregroundColor(.primary)
                
                Text("\(Int(shift.hoursWorked)) tiếng")
                    .font(isIphone ? .caption : .title3)
                    .foregroundColor(.secondary)
            }
            .padding(isIphone ? 12 : 16)
            .frame(minWidth: isIphone ? 100 : 120)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(isIphone ? 8 : 12)
            .overlay(
                RoundedRectangle(cornerRadius: isIphone ? 8 : 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Work Schedule Summary
    private var workScheduleSummary: some View {
        VStack(spacing: isIphone ? 12 : 16) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: isIphone ? 4 : 8) {
                    Text("Tổng giờ làm việc:")
                        .font(isIphone ? .subheadline : .title3)
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedWeeklyHours)
                        .font(isIphone ? .headline : .title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: isIphone ? 4 : 8) {
                    Text("Lương tháng dự tính:")
                        .font(isIphone ? .subheadline : .title3)
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedEstimatedMonthlySalary)
                        .font(isIphone ? .headline : .title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(isIphone ? 16 : 20)
            .background(Color(.systemGray6))
            .cornerRadius(isIphone ? 12 : 16)
        }
    }
    
    // MARK: - Validation Errors View
    private var validationErrorsView: some View {
        VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
            ForEach(viewModel.getValidationErrors(), id: \.errorDescription) { error in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(error.errorDescription ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, isIphone ? 16 : 32)
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button {
            Task {
                focusedField = nil
                await viewModel.saveStaff()
                if viewModel.getValidationErrors().isEmpty {
                    appState.coordinator.dismiss(style: .present)
                }
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(isIphone ? 1.0 : 1.2)
                } else {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(isIphone ? .title3 : .title)
                    Text(isEditing ? "Cập nhật" : "Thêm nhân viên")
                        .font(isIphone ? .headline : .title2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(isIphone ? 16 : 20)
            .background(
                LinearGradient(
                    colors: viewModel.isFormValid ? [appState.currentTabThemeColors.primaryColor, appState.currentTabThemeColors.secondaryColor] : [.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(isIphone ? 15 : 20)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.horizontal, isIphone ? 16 : 32)
        .padding(.bottom, isIphone ? 16 : 32)
    }
    
    // MARK: - Helper Methods
    private func formatCurrency(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    private func formSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: isIphone ? 16 : 20) {
            Label(title, systemImage: systemImage)
                .font(isIphone ? .headline : .title)
                .foregroundColor(.primary)
            
            content()
                .padding(isIphone ? 16 : 24)
                .background(Color(.systemBackground))
                .cornerRadius(isIphone ? 16 : 20)
        }
    }
} 
