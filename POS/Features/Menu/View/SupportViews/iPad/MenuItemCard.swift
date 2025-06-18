//
//  MenuItemCard.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 13/6/25.
//

import SwiftUI

struct MenuItemCard: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: OrderViewModel
    
    @State private var temperature: TemperatureOption = .hot
    @State private var consumption: ConsumptionOption = .stay
    @State private var isHovered = false
    @State private var isPressed = false
    
    private let item: MenuItem
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: OrderViewModel, item: MenuItem) {
        self.viewModel = viewModel
        self.item = item
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            menuItemImage()
            menuItemDetail()
            selectionSection()
            addItemButton()
        }
        .padding(20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
    }
}

// MARK: - Components
extension MenuItemCard {
    
    // MARK: - Menu Item Temp Image
    private func menuItemImage() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .aspectRatio(16/9, contentMode: .fit)
                .middleLayer(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 20)
            
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    appState.currentTabThemeColors.gradient(for: colorScheme)
                )
                //.topLayer(tabThemeColors: appState.currentThemeColors)
        }
    }
    
    // MARK: - Item Detail
    private func menuItemDetail() -> some View {
        // MARK: - Name And Price
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title3.weight(.bold))
                    .lineLimit(2)
                    .foregroundStyle(appState.currentTabThemeColors.textGradient(for: colorScheme))
                
                Text("\(String(format: "%.0f", item.price))")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
            }
            
            Spacer()
        }
    }
    
    private func selectionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Temperature Selector
            SelectorView(
                title: "Temperature",
                options: TemperatureOption.allCases,
                selection: $temperature,
                getIcon: { $0 == .hot ? "thermometer.sun.fill" : "thermometer.snowflake" },
                getColors: { option, isSelected, _ in
                    let gradient = option == .hot ?
                    LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [.blue.opacity(0.8), .cyan.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    let primary = option == .hot ? Color.orange : Color.blue
                    return (gradient, primary)
                }
            )
            
            // Consumption Selector
            SelectorView(
                title: "Dining Option",
                options: ConsumptionOption.allCases,
                selection: $consumption,
                getIcon: { $0 == .stay ? "house.fill" : "takeoutbag.and.cup.and.straw.fill" },
                getColors: { _, _, colorScheme in
                    (appState.currentTabThemeColors.gradient(for: colorScheme),
                     appState.currentTabThemeColors.primaryColor)
                }
            )
        }
    }
    
    // MARK: - Add Button
    private func addItemButton() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18, weight: .semibold))
            Text("Add to Cart")
                .font(.callout.weight(.semibold))
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                do {
                    try viewModel.addItemToOrder(item, temperature, consumption)
                    temperature = .hot
                    consumption = .stay
                } catch {
                    appState.sourceModel.handleError(error)
                }
            }
        }
    }
}

// MARK: - Generic Selector Component
struct SelectorView<T: CaseIterable & Hashable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    let options: [T]
    @Binding var selection: T
    let getIcon: (T) -> String
    let getColors: (T, Bool, ColorScheme) -> (gradient: LinearGradient, primary: Color)
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    SelectorButton(
                        option: option,
                        isSelected: selection == option,
                        icon: getIcon(option),
                        colors: getColors(option, selection == option, colorScheme)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = option
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Selector Button Component
struct SelectorButton<T: RawRepresentable>: View where T.RawValue == String {
    let option: T
    let isSelected: Bool
    let icon: String
    let colors: (gradient: LinearGradient, primary: Color)
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(isSelected ? colors.gradient : defaultGradient)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                // Label
                Text(option.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(buttonBackground)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var defaultGradient: LinearGradient {
        LinearGradient(colors: [Color(.systemGray5), Color(.systemGray4)], startPoint: .top, endPoint: .bottom)
    }
    
    private var shadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1)
    }
    
    private var buttonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? .regularMaterial : .ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? colors.primary.opacity(0.3) : Color(.systemGray4).opacity(0.5),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                )
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? colors.gradient : defaultGradient)
        }
    }
}
