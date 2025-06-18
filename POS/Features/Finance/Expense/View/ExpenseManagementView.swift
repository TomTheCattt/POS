//
//  ExpenseManagementView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI
import Combine
    
struct ExpenseManagementView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @EnvironmentObject var appState: AppState
    @State private var selectedMonth = Date()
    @State private var showingAddExpenseSheet = false
    @State private var selectedCategory: ExpenseCategory?
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderView(
                title: "Quản lý thu chi",
                onAddExpense: {
                    showingAddExpenseSheet = true
                }
            )
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : -20)
            
            // Month picker và Category filter
            VStack(spacing: 12) {
                MonthYearPickerView(selectedDate: $selectedMonth)
                CategoryFilterView(selectedCategory: $selectedCategory)
            }
            .padding()
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // Summary cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ExpenseSummaryCard(
                        title: "Tổng chi phí",
                        amount: viewModel.totalExpenses,
                        icon: "arrow.down.circle.fill",
                        color: .red
                    )
                    
                    ExpenseSummaryCard(
                        title: "Đã duyệt",
                        amount: viewModel.approvedExpenses,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    ExpenseSummaryCard(
                        title: "Chờ duyệt",
                        amount: viewModel.pendingExpenses,
                        icon: "clock.fill",
                        color: .orange
                    )
                }
                .padding()
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if viewModel.isOwner {
                        RecurringExpensesSection(
                            expenses: viewModel.filteredRecurringExpenses(category: selectedCategory),
                            onApprove: viewModel.approveExpense,
                            onReject: viewModel.rejectExpense
                        )
                    }
                    
                    DailyExpensesSection(
                        expenses: viewModel.filteredDailyExpenses(category: selectedCategory),
                        isOwner: viewModel.isOwner,
                        onApprove: viewModel.approveExpense,
                        onReject: viewModel.rejectExpense
                    )
                }
                .padding(.horizontal)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            AddExpenseSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Custom Header View
struct CustomHeaderView: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    let onAddExpense: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            // Title
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    appState.sourceModel.currentThemeColors.expense.primaryColor
                )
            
            Spacer()
            
            // Add expense button
            Button(action: onAddExpense) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(
                        appState.sourceModel.currentThemeColors.expense.gradient(for: colorScheme)
                    )
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Category Filter
struct CategoryFilterView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedCategory: ExpenseCategory?
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "Tất cả",
                    icon: "list.bullet",
                    color: .indigo,
                    isSelected: selectedCategory == nil,
                    count: nil,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = nil
                    }
                }
                
                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayTitle,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category,
                        count: Int.random(in: 1...10), // Replace with actual count
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    //.shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(appState.sourceModel.currentThemeColors.expense.softGradient(for: colorScheme))
            }
        )
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let count: Int?
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.3) : color.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.gradient)
                            .matchedGeometryEffect(id: "background", in: namespace)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Recurring Expenses Section
struct RecurringExpensesSection: View {
    let expenses: [GroupedExpenses]
    let onApprove: (ExpenseItem) -> Void
    let onReject: (ExpenseItem) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Thu chi định kỳ",
                icon: "repeat.circle.fill",
                color: .blue,
                count: expenses.reduce(0) { $0 + $1.items.count }
            )
            
            ForEach(expenses) { group in
                GroupCard(
                    group: group,
                    isRecurring: true,
                    onApprove: onApprove,
                    onReject: onReject
                )
            }
        }
    }
}

// MARK: - Daily Expenses Section
struct DailyExpensesSection: View {
    let expenses: [GroupedExpenses]
    let isOwner: Bool
    let onApprove: (ExpenseItem) -> Void
    let onReject: (ExpenseItem) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Thu chi theo ngày",
                icon: "calendar.circle.fill",
                color: .green,
                count: expenses.reduce(0) { $0 + $1.items.count }
            )
            
            ForEach(expenses) { group in
                GroupCard(
                    group: group,
                    isRecurring: false,
                    onApprove: onApprove,
                    onReject: onReject
                )
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.title2.bold())
                
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
    }
}

struct GroupCard: View {
    let group: GroupedExpenses
    let isRecurring: Bool
    let onApprove: (ExpenseItem) -> Void
    let onReject: (ExpenseItem) -> Void
    
    @State private var isExpanded = false
    
    var totalAmount: Double {
        group.items.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline.bold())
                        
                        Text("\(group.items.count) giao dịch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(totalAmount.formatted(.currency(code: "VND")))
                            .font(.headline.bold())
                            .foregroundColor(totalAmount >= 0 ? .green : .red)
                        
                        if isRecurring {
                            Label("Định kỳ", systemImage: "repeat")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Divider()
                
                VStack(spacing: 12) {
                    ForEach(group.items) { expense in
                        ExpenseItemRow(
                            expense: expense,
                            onApprove: { onApprove(expense) },
                            onReject: { onReject(expense) }
                        )
                        .padding(.horizontal, 16)
                        
                        if expense.id != group.items.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Expense Item Row
struct ExpenseItemRow: View {
    let expense: ExpenseItem
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main info
            HStack(alignment: .top, spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: expense.category.icon)
                        .foregroundColor(expense.category.color)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(expense.description)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if expense.isRecurring {
                            Label(expense.recurringType?.displayTitle ?? "", systemImage: "repeat")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        Text("Tạo: \(expense.createdAt.formatted(.dateTime.hour().minute()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.amount.formatted(.currency(code: "VND")))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(expense.amount < 0 ? .red : .green)
                    
                    StatusTag(status: expense.status)
                }
            }
            
            // Approval timestamp
            if let approvedAt = expense.approvedAt {
                HStack {
                    Spacer()
                    Text("Duyệt: \(approvedAt.formatted(.dateTime.hour().minute()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }
            
            // Action buttons if pending
            if expense.status == .pending {
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button(action: onReject) {
                        Label("Từ chối", systemImage: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.gradient)
                            .cornerRadius(20)
                    }
                    
                    Button(action: onApprove) {
                        Label("Duyệt", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.gradient)
                            .cornerRadius(20)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Supporting Views

struct MonthYearPickerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedDate: Date
    @State private var isAnimating = false
    
    private var monthRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let currentDate = Date()
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: currentDate)!
        let sixMonthsLater = calendar.date(byAdding: .month, value: 6, to: currentDate)!
        return sixMonthsAgo...sixMonthsLater
    }
    
    private var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate))!
    }
    
    private var monthEnd: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Month Navigation
            HStack(spacing: 24) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate),
                           monthRange.contains(newDate) {
                            selectedDate = newDate
                            animateButton()
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(appState.sourceModel.currentThemeColors.expense.gradient(for: colorScheme))
                        )
                        //.shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(isAnimating ? 0.95 : 1)
                }
                
                VStack(spacing: 4) {
                    Text(selectedDate.formatted(.dateTime.month().year()))
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("\(monthStart.formatted(.dateTime.day())) - \(monthEnd.formatted(.dateTime.day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 150)
                .padding(.vertical, 8)
                .background(
                    Color.clear
                )
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate),
                           monthRange.contains(newDate) {
                            selectedDate = newDate
                            animateButton()
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(appState.sourceModel.currentThemeColors.expense.gradient(for: colorScheme))
                        )
                        //.shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(isAnimating ? 0.95 : 1)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
        }
    }
    
    private func animateButton() {
        isAnimating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAnimating = false
        }
    }
}

struct ExpenseSummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(amount.formatted(.currency(code: "VND")))
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(width: 180, height: 110)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                //.shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatusTag: View {
    let status: ExpenseStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.displayTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
    }
}

// MARK: - Add Expense Sheet
struct AddExpenseSheet: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var description = ""
    @State private var amount = ""
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var isRecurring = false
    @State private var selectedRecurringType: RecurringType = .monthly
    @State private var expenseDate = Date()
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var isLoading = false
    
    private var isValidForm: Bool {
        !description.isEmpty &&
        !amount.isEmpty &&
        (Double(amount) ?? 0) != 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header với icon lớn
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(selectedCategory.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: selectedCategory.icon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(selectedCategory.color)
                        }
                        
                        Text("Thêm khoản thu chi")
                            .font(.title2.bold())
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Thông tin cơ bản
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle("Thông tin cơ bản")
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Mô tả",
                                    text: $description,
                                    icon: "text.alignleft",
                                    placeholder: "Nhập mô tả chi tiết..."
                                )
                                
                                CustomTextField(
                                    title: "Số tiền (VND)",
                                    text: $amount,
                                    icon: "dollarsign.circle",
                                    placeholder: "0"
                                )
                                
                                CategoryPickerView(selectedCategory: $selectedCategory)
                            }
                        }
                        
                        // Thời gian
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle("Thời gian")
                            
                            VStack(spacing: 12) {
                                CustomDatePicker(
                                    title: "Ngày phát sinh",
                                    date: $expenseDate
                                )
                                
                                CustomToggle(
                                    title: "Thu chi định kỳ",
                                    subtitle: "Tự động tạo các khoản thu chi tương tự",
                                    isOn: $isRecurring
                                )
                                
                                if isRecurring {
                                    RecurringTypePickerView(selectedType: $selectedRecurringType)
                                }
                            }
                        }
                        
                        // Chứng từ
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle("Chứng từ đính kèm")
                            
//                            AttachmentSection(
//                                selectedImages: $selectedImages,
//                                showingImagePicker: $showingImagePicker
//                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await saveExpense()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                
                                Text(isLoading ? "Đang lưu..." : "Thêm khoản thu chi")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isValidForm ? selectedCategory.color.gradient : Color.gray.gradient)
                            )
                        }
                        .disabled(!isValidForm || isLoading)
                        .padding(.horizontal, 20)
                        
                        Button("Hủy") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            // ImagePicker(images: $selectedImages)
        }
    }
    
    private func saveExpense() async {
        isLoading = true
        
        guard let amountValue = Double(amount) else {
            isLoading = false
            return
        }
        
        let expense = ExpenseItem(
            shopId: "",
            amount: amountValue,
            description: description,
            category: selectedCategory,
            expenseDate: expenseDate,
            isRecurring: isRecurring,
            recurringType: isRecurring ? selectedRecurringType : nil,
            status: .pending,
            attachmentUrls: [],
            createdBy: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            var attachmentUrls: [String] = []
            for image in selectedImages {
                if let url = try await viewModel.uploadAttachment(image) {
                    attachmentUrls.append(url)
                }
            }
            
            var finalExpense = expense
            finalExpense.attachmentUrls = attachmentUrls
            
            try await viewModel.addExpense(finalExpense)
            dismiss()
        } catch {
            print("Error saving expense: \(error)")
        }
        
        isLoading = false
    }
}

struct SectionTitle: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline.bold())
            .foregroundColor(.primary)
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: ExpenseCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Loại thu chi")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedCategory == category ? category.color : Color(.systemGray5))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: category.icon)
                                        .foregroundColor(selectedCategory == category ? .white : .secondary)
                                        .font(.title3)
                                }
                                
                                Text(category.displayTitle)
                                    .font(.caption)
                                    .foregroundColor(selectedCategory == category ? category.color : .secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(selectedCategory == category ? 1.1 : 1.0)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
    }
}

struct CustomDatePicker: View {
    let title: String
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct CustomToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct RecurringTypePickerView: View {
    @Binding var selectedType: RecurringType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chu kỳ lặp lại")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                ForEach(RecurringType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                    } label: {
                        Text(type.displayTitle)
                            .font(.subheadline.bold())
                            .foregroundColor(selectedType == type ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedType == type ? Color.blue.gradient : Color(.systemGray5).gradient)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Supporting Models
struct GroupedExpenses: Identifiable {
    let id = UUID()
    let date: Date
    var items: [ExpenseItem]
}

// MARK: - Extensions
extension ExpenseCategory {
    var displayTitle: String {
        switch self {
        case .utilities: return "Tiện ích"
        case .inventory: return "Nhập hàng"
        case .salary: return "Lương"
        case .rent: return "Thuê mặt bằng"
        case .equipment: return "Thiết bị"
        case .marketing: return "Marketing"
        case .maintenance: return "Bảo trì"
        case .other: return "Khác"
        }
    }

    var icon: String {
        switch self {
        case .utilities:
            return "bolt.circle.fill" // Icon năng lượng
        case .inventory:
            return "shippingbox.circle.fill" // Icon hộp hàng
        case .salary:
            return "person.2.circle.fill" // Icon nhóm người
        case .rent:
            return "building.2.crop.circle.fill" // Icon tòa nhà
        case .equipment:
            return "laptopcomputer.and.iphone" // Icon thiết bị
        case .marketing:
            return "megaphone.fill" // Icon marketing
        case .maintenance:
            return "wrench.and.screwdriver.fill" // Icon công cụ
        case .other:
            return "questionmark.circle.fill" // Icon khác
        }
    }

    var color: Color {
        switch self {
        case .utilities:
            return Color(hex: "4361EE") // Xanh dương đậm
        case .inventory:
            return Color(hex: "F72585") // Hồng đậm
        case .salary:
            return Color(hex: "7209B7") // Tím đậm
        case .rent:
            return Color(hex: "3A0CA3") // Tím than
        case .equipment:
            return Color(hex: "4CC9F0") // Xanh biển
        case .marketing:
            return Color(hex: "FB8500") // Cam đậm
        case .maintenance:
            return Color(hex: "2EC4B6") // Xanh ngọc
        case .other:
            return Color(hex: "6C757D") // Xám trung tính
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .utilities:
            return LinearGradient(
                colors: [Color(hex: "4361EE"), Color(hex: "4CC9F0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .inventory:
            return LinearGradient(
                colors: [Color(hex: "F72585"), Color(hex: "7209B7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .salary:
            return LinearGradient(
                colors: [Color(hex: "7209B7"), Color(hex: "3A0CA3")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rent:
            return LinearGradient(
                colors: [Color(hex: "3A0CA3"), Color(hex: "4361EE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .equipment:
            return LinearGradient(
                colors: [Color(hex: "4CC9F0"), Color(hex: "2EC4B6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .marketing:
            return LinearGradient(
                colors: [Color(hex: "FB8500"), Color(hex: "F72585")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .maintenance:
            return LinearGradient(
                colors: [Color(hex: "2EC4B6"), Color(hex: "4361EE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .other:
            return LinearGradient(
                colors: [Color(hex: "6C757D"), Color(hex: "495057")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Helper Extensions
extension ExpenseItem {
    func copy() -> ExpenseItem? {
        guard let data = try? JSONEncoder().encode(self),
              let copy = try? JSONDecoder().decode(ExpenseItem.self, from: data)
        else { return nil }
        return copy
    }
}

extension ExpenseStatus {
    var displayTitle: String {
        switch self {
        case .pending: return "Chờ duyệt"
        case .approved: return "Đã duyệt"
        case .rejected: return "Từ chối"
        case .cancelled: return "Đã hủy"
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock.circle.fill" // Icon đồng hồ
        case .approved:
            return "checkmark.circle.fill" // Icon tick
        case .rejected:
            return "xmark.circle.fill" // Icon X
        case .cancelled:
            return "minus.circle.fill" // Icon gạch ngang
        }
    }

    var color: Color {
        switch self {
        case .pending:
            return Color(hex: "FF9F1C") // Cam vàng
        case .approved:
            return Color(hex: "2EC4B6") // Xanh ngọc
        case .rejected:
            return Color(hex: "E71D36") // Đỏ tươi
        case .cancelled:
            return Color(hex: "6C757D") // Xám trung tính
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .pending:
            return LinearGradient(
                colors: [Color(hex: "FF9F1C"), Color(hex: "FFBF69")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .approved:
            return LinearGradient(
                colors: [Color(hex: "2EC4B6"), Color(hex: "80ED99")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rejected:
            return LinearGradient(
                colors: [Color(hex: "E71D36"), Color(hex: "FF4D6D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cancelled:
            return LinearGradient(
                colors: [Color(hex: "6C757D"), Color(hex: "ADB5BD")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var animation: Animation {
        switch self {
        case .pending:
            return .easeInOut(duration: 1.0).repeatForever(autoreverses: true) // Nhấp nháy nhẹ
        case .approved:
            return .spring(response: 0.3, dampingFraction: 0.6) // Nảy lên
        case .rejected:
            return .easeInOut(duration: 0.3) // Mượt mà
        case .cancelled:
            return .easeOut(duration: 0.2) // Nhanh
        }
    }

    var systemImage: some View {
        Image(systemName: icon)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(gradient)
    }

    var badge: some View {
        HStack(spacing: 8) {
            systemImage
                .frame(width: 24, height: 24)
            
            Text(displayTitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
    }

    var tag: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(displayTitle)
                .font(.caption.weight(.medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}
