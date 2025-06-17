//
//  CompactMenuItemCard.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 13/6/25.
//

import SwiftUI

struct CompactMenuItemCard: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: OrderViewModel
    let item: MenuItem
    
    @State private var isExpanded = false
    @State private var selectedTemperature: TemperatureOption = .hot
    @State private var selectedConsumption: ConsumptionOption = .stay
    @State private var isPressed = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(spacing: 10) {
                // Item Image với gradient đẹp hơn
                menuItemImage()
                
                VStack(alignment: .leading, spacing: 8) {
                    menuItemDetail()
                    toggleButton()
                    if isExpanded {
                        VStack(spacing: 12) {
                            Divider()
                                .background(appState.currentTabThemeColors.primaryColor.opacity(0.3))
                            
                            VStack(spacing: 12) {
                                // Temperature options
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "thermometer")
                                            .font(.system(size: 12))
                                            .foregroundColor(appState.currentTabThemeColors.primaryColor)
                                        Text("Nhiệt độ")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        ForEach(TemperatureOption.allCases, id: \.self) { option in
                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedTemperature = option
                                                }
                                            } label: {
                                                VStack(spacing: 6) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(
                                                                selectedTemperature == option ?
                                                                (option == .hot ?
                                                                 LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                                                 LinearGradient(colors: [.blue, .cyan.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                                ) :
                                                                LinearGradient(colors: [Color(.systemGray5), Color(.systemGray4)], startPoint: .top, endPoint: .bottom)
                                                            )
                                                            .frame(width: 20, height: 20)
                                                        
                                                        Image(systemName: option == .hot ? "thermometer.sun.fill" : "thermometer.snowflake")
                                                            .font(.system(size: 8, weight: .bold))
                                                            .foregroundColor(selectedTemperature == option ? .white : .secondary)
                                                    }
                                                    
                                                    Text(option.rawValue)
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(
                                                            selectedTemperature == option ?
                                                            (option == .hot ? .orange : .blue) :
                                                            .secondary
                                                        )
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(
                                                            selectedTemperature == option ?
                                                            .regularMaterial :
                                                            .ultraThinMaterial
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .stroke(
                                                                    selectedTemperature == option ?
                                                                    (option == .hot ? .orange.opacity(0.5) : .blue.opacity(0.5)) :
                                                                    Color(.systemGray4).opacity(0.5),
                                                                    lineWidth: selectedTemperature == option ? 1.5 : 0.5
                                                                )
                                                        )
                                                )
                                            }
                                            .scaleEffect(selectedTemperature == option ? 1.02 : 1.0)
                                        }
                                    }
                                }
                                
                                // Consumption options
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "location")
                                            .font(.system(size: 12))
                                            .foregroundColor(appState.sourceModel.currentThemeColors.order.primaryColor)
                                        Text("Loại dịch vụ")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        ForEach(ConsumptionOption.allCases, id: \.self) { option in
                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedConsumption = option
                                                }
                                            } label: {
                                                VStack(spacing: 6) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(
                                                                selectedConsumption == option ?
                                                                appState.currentTabThemeColors.gradient(for: colorScheme) :
                                                                LinearGradient(colors: [Color(.systemGray5), Color(.systemGray4)], startPoint: .top, endPoint: .bottom)
                                                            )
                                                            .frame(width: 20, height: 20)
                                                        
                                                        Image(systemName: option == .stay ? "house.fill" : "takeoutbag.and.cup.and.straw.fill")
                                                            .font(.system(size: 8, weight: .bold))
                                                            .foregroundColor(selectedConsumption == option ? .white : .secondary)
                                                    }
                                                    
                                                    Text(option.rawValue)
                                                        .font(.system(size: 10, weight: .medium))
                                                        .lineLimit(2)
                                                        .foregroundColor(
                                                            selectedConsumption == option ?
                                                            appState.sourceModel.currentThemeColors.order.primaryColor :
                                                            .secondary
                                                        )
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(
                                                            selectedConsumption == option ?
                                                            .regularMaterial :
                                                            .ultraThinMaterial
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .stroke(
                                                                    selectedConsumption == option ?
                                                                    appState.sourceModel.currentThemeColors.order.primaryColor.opacity(0.5) :
                                                                    Color(.systemGray4).opacity(0.5),
                                                                    lineWidth: selectedConsumption == option ? 1.5 : 0.5
                                                                )
                                                        )
                                                )
                                            }
                                            .scaleEffect(selectedConsumption == option ? 1.02 : 1.0)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95, anchor: .top).combined(with: .opacity).combined(with: .offset(y: -10)),
                            removal: .scale(scale: 0.98, anchor: .top).combined(with: .opacity).combined(with: .offset(y: -5))
                        ))
                    }
                    addButton()
                }
            }
            .padding(14)
        }
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
    }
}

// MARK: - Components
extension CompactMenuItemCard {
    
    // MARK: - Menu Item Temp Image
    private func menuItemImage() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .middleLayer(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 14)
                .frame(height: 60)
            
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
        }
    }
    
    // MARK: - Item Detail (Redesigned)
    private func menuItemDetail() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Tên món - hàng đầu tiên
            Text(item.name)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(appState.currentTabThemeColors.textGradient(for: colorScheme))
            
            // Giá - hàng thứ hai
            HStack {
                Text("\(String(format: "%.0f", item.price)) đ")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(appState.currentTabThemeColors.textGradient(for: colorScheme))
                
                Spacer()
            }
        }
    }
    
    private func toggleButton() -> some View {
        HStack(spacing: 6) {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "slider.horizontal.3")
                .font(.system(size: 12, weight: .medium))
            
            Text(isExpanded ? "Thu gọn" : "Tùy chọn")
                .font(.system(size: 12, weight: .medium))
            
            Spacer()
            
            if !isExpanded {
                HStack(spacing: 4) {
                    Image(systemName: selectedTemperature == .hot ? "thermometer.sun.fill" : "thermometer.snowflake")
                        .font(.system(size: 10))
                        .foregroundColor(selectedTemperature == .hot ? .orange : .blue)
                    
                    Image(systemName: selectedConsumption == .stay ? "house.fill" : "takeoutbag.and.cup.and.straw.fill")
                        .font(.system(size: 10))
                        .foregroundColor(appState.currentTabThemeColors.primaryColor)
                }
            }
        }
        //.foregroundColor(appState.currentTabThemeColors.primaryColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
    
    private func addButton() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14, weight: .semibold))
            
            Text("Thêm vào giỏ")
                .font(.system(size: 13, weight: .semibold))
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.addItemToOrder(item, selectedTemperature, selectedConsumption)
                selectedTemperature = .hot
                selectedConsumption = .stay
            }
        }
    }
}
