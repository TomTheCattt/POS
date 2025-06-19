//
//  OrderItemView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 13/6/25.
//

import SwiftUI

struct OrderItemView: View {
    @ObservedObject private var viewModel: OrderViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    private let item: OrderItem
    private let deleteButtonWidth: CGFloat = 80
    
    init(viewModel: OrderViewModel, item: OrderItem) {
        self.viewModel = viewModel
        self.item = item
    }
    
    var body: some View {
        ZStack {
            deleteButtonBackground
            mainContent
        }
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
    }
}

// MARK: - Main Components
private extension OrderItemView {
    
    var deleteButtonBackground: some View {
        HStack {
            Spacer()
            deleteButton
        }
    }
    
    var mainContent: some View {
        HStack(spacing: 12) {
            itemImage
            itemDetails
            Spacer()
            quantityAndPriceSection
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appState.currentTabThemeColors.primaryColor.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .offset(x: viewModel.orderItemOffset)
        .simultaneousGesture(swipeGesture)
    }
}

// MARK: - Delete Button
private extension OrderItemView {
    
    var deleteButton: some View {
        Button {
            withAnimation(.spring()) {
                viewModel.removeOrderItem(itemId: item.id)
            }
        } label: {
            deleteButtonContent
        }
        .opacity(viewModel.showingDeleteButton ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showingDeleteButton)
    }
    
    var deleteButtonContent: some View {
        VStack(spacing: 4) {
            Image(systemName: "trash.fill")
                .font(.system(size: 20, weight: .semibold))
            Text("Xóa")
                .font(.caption.weight(.medium))
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .frame(maxHeight: .infinity)
        .frame(width: deleteButtonWidth)
        .background(Color.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        //.shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Item Image
private extension OrderItemView {
    
    var itemImage: some View {
        ZStack {
            itemImageBackground
            itemImageIcon
        }
    }
    
    var itemImageBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(itemImageGradient)
            .frame(width: 50, height: 50)
    }
    
    var itemImageGradient: LinearGradient {
        colorScheme == .dark ?
        LinearGradient(
            colors: [Color.systemGray6, Color.systemGray3],
            startPoint: .top,
            endPoint: .bottom
        ) :
        appState.currentTabThemeColors.gradient(for: colorScheme)
    }
    
    var itemImageIcon: some View {
        Image(systemName: "cup.and.saucer.fill")
            .foregroundStyle(itemImageIconColor)
    }
    
    var itemImageIconColor: Color {
        colorScheme == .dark ?
        appState.currentTabThemeColors.secondaryColor :
        .white
    }
}

// MARK: - Item Details
private extension OrderItemView {
    
    var itemDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            itemName
            itemBadges
        }
    }
    
    var itemName: some View {
        Text(item.name)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.primary)
            .lineLimit(1)
    }
    
    var itemBadges: some View {
        VStack(alignment: .leading, spacing: 8) {
            temperatureBadge
            consumptionBadge
        }
    }
    
    var temperatureBadge: some View {
        HStack(spacing: 4) {
            temperatureIcon
            temperatureText
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(temperatureGradient)
        .foregroundColor(.primary)
        .clipShape(Capsule())
    }
    
    var temperatureIcon: some View {
        Image(systemName: item.temperature == .hot ? "thermometer.sun.fill" : "thermometer.snowflake")
            .font(.system(size: 10))
    }
    
    var temperatureText: some View {
        Text(item.temperature.rawValue)
            .font(.caption2.weight(.medium))
    }
    
    var temperatureGradient: LinearGradient {
        item.temperature == .hot ?
        LinearGradient(
            colors: [.orange.opacity(0.8), .red.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ) :
        LinearGradient(
            colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var consumptionBadge: some View {
        HStack(spacing: 4) {
            consumptionIcon
            consumptionText
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(consumptionBackground)
        .foregroundColor(.primary)
        .clipShape(Capsule())
    }
    
    var consumptionIcon: some View {
        Image(systemName: item.consumption == .stay ? "house.fill" : "takeoutbag.and.cup.and.straw.fill")
            .font(.system(size: 10))
    }
    
    var consumptionText: some View {
        Text(item.consumption.rawValue)
            .font(.caption2.weight(.medium))
    }
    
    var consumptionBackground: some View {
        appState.currentTabThemeColors.gradient(for: colorScheme).opacity(0.15)
    }
}

// MARK: - Quantity and Price Section
private extension OrderItemView {
    
    var quantityAndPriceSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            quantityControls
            noteButton
        }
    }
    
    var quantityControls: some View {
        HStack(spacing: 12) {
            decrementButton
            quantityText
            incrementButton
        }
    }
    
    var decrementButton: some View {
        Button {
            withAnimation(.spring()) {
                handleDecrementAction()
            }
        } label: {
            Image(systemName: item.quantity > 1 ? "minus.circle.fill" : "trash.circle.fill")
                .foregroundColor(decrementButtonColor)
                .font(.system(size: 20))
        }
    }
    
    var decrementButtonColor: Color {
        item.quantity > 1 ?
        appState.currentTabThemeColors.primaryColor :
        .red
    }
    
    var quantityText: some View {
        Text("\(item.quantity)")
            .font(.subheadline.weight(.bold))
            .foregroundColor(.primary)
            .frame(minWidth: 20)
    }
    
    var incrementButton: some View {
        Button {
            withAnimation(.spring()) {
                do {
                    try viewModel.updateOrderItemQuantity(for: item.id, increment: true)
                } catch {
                    appState.sourceModel.handleError(error)
                }
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
                .font(.system(size: 20))
        }
    }
    
    var noteButton: some View {
        Button {
            appState.coordinator.navigateTo(.note(item), using: .present)
        } label: {
            HStack(spacing: 8) {
                noteText
                noteIcon
            }
        }
    }
    
    var noteText: some View {
        Text(item.note ?? "Thêm ghi chú")
            .foregroundColor(.primary)
            .font(.footnote)
            .lineLimit(2)
    }
    
    var noteIcon: some View {
        Image(systemName: item.note?.isEmpty ?? true ? "square.and.pencil" : "note.text")
            .font(.system(size: 16))
            .foregroundStyle(appState.currentTabThemeColors.primaryColor)
            .frame(width: 32, height: 32)
    }
}

// MARK: - Gestures
private extension OrderItemView {
    
    var swipeGesture: some Gesture {
        DragGesture()
            .onChanged(handleSwipeChanged)
            .onEnded(handleSwipeEnded)
    }
    
    func handleSwipeChanged(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = abs(value.translation.height)
        
        guard abs(horizontal) > vertical else { return }
        guard horizontal < 0 else {
            viewModel.orderItemOffset = 0
            viewModel.showingDeleteButton = false
            return
        }
        
        viewModel.orderItemOffset = max(horizontal, -deleteButtonWidth)
    }
    
    func handleSwipeEnded(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = abs(value.translation.height)
        
        guard abs(horizontal) > vertical else { return }
        
        withAnimation(.spring()) {
            if horizontal < -deleteButtonWidth / 2 {
                viewModel.orderItemOffset = -deleteButtonWidth
                viewModel.showingDeleteButton = true
            } else {
                viewModel.orderItemOffset = 0
                viewModel.showingDeleteButton = false
            }
        }
    }
}

// MARK: - Helper Methods
private extension OrderItemView {
    
    func handleDecrementAction() {
        do {
            if item.quantity > 1 {
                try viewModel.updateOrderItemQuantity(for: item.id, increment: false)
            } else {
                viewModel.removeOrderItem(itemId: item.id)
            }
        } catch {
            appState.sourceModel.handleError(error)
        }
    }
}
