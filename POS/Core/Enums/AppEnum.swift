//
//  AppEnum.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI

enum SuggestedCategories: String, CaseIterable, Identifiable {
    case coffee
    case espresso
    case tea
    case milkTea
    case smoothie
    case juice
    case soda
    case iceBlended
    case hotDrinks
    case coldDrinks
    case topping
    case snacks

    var id: String { rawValue }

    var name: String {
        switch self {
        case .coffee: return "Coffee"
        case .espresso: return "Espresso"
        case .tea: return "Tea"
        case .milkTea: return "Milk Tea"
        case .smoothie: return "Smoothie"
        case .juice: return "Juice"
        case .soda: return "Soda"
        case .iceBlended: return "Ice Blended"
        case .hotDrinks: return "Hot Drinks"
        case .coldDrinks: return "Cold Drinks"
        case .topping: return "Topping"
        case .snacks: return "Snacks"
        }
    }

    var icon: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .espresso: return "flame.fill"
        case .tea: return "leaf.fill"
        case .milkTea: return "drop.fill"
        case .smoothie: return "wind"
        case .juice: return "drop.circle.fill"
        case .soda: return "bubbles.and.sparkles"
        case .iceBlended: return "snowflake"
        case .hotDrinks: return "thermometer.sun.fill"
        case .coldDrinks: return "thermometer.snowflake"
        case .topping: return "circle.grid.2x2.fill"
        case .snacks: return "takeoutbag.and.cup.and.straw.fill"
        }
    }

    var color: Color {
        switch self {
        case .coffee: return .brown
        case .espresso: return .orange
        case .tea: return .green
        case .milkTea: return .purple
        case .smoothie: return .pink
        case .juice: return .red
        case .soda: return .blue
        case .iceBlended: return .cyan
        case .hotDrinks: return .orange
        case .coldDrinks: return .blue
        case .topping: return .indigo
        case .snacks: return .yellow
        }
    }
}

enum AppTextField: Hashable, Identifiable {
    
    case signInSection(SignInField)
    case signUpSection(SignUpField)
    case addMenuItemSection(AddMenuItemSectionField)
    case addStaffSection(AddStaffSectionField)
    case passwordManagementSection(PasswordManagementSectionField)
    case searchBar(SearchBarField)
    case note(NoteField)
    
    enum SignInField: String, Hashable {
        case email, password
    }

    enum SignUpField: String, Hashable {
        case email, userName, ownerPassword, password, rePassword
    }

    enum AddMenuItemSectionField: String, Hashable {
        case name, price, category
    }

    enum AddStaffSectionField: String, Hashable {
        case name, hourlyRate
    }

    enum PasswordManagementSectionField: String, Hashable {
        case currentPassword, newPassword, confirmPassword
        case currentOwnerPassword, newOwnerPassword, confirmOwnerPassword
    }
    enum SearchBarField: String, Hashable {
        case menuItem, ingredientItem, customer
    }
    
    enum NoteField: String, Hashable {
        case note
    }
    
    var id: String {
        switch self {
        case .signInSection(let field): return "signIn.\(field.rawValue)"
        case .signUpSection(let field): return "signUp.\(field.rawValue)"
        case .addMenuItemSection(let field): return "menuItem.\(field.rawValue)"
        case .addStaffSection(let field): return "staff.\(field.rawValue)"
        case .passwordManagementSection(let field): return "password.\(field.rawValue)"
        case .searchBar(let field): return "searchBar.\(field.rawValue)"
        case .note(let field): return "note.\(field.rawValue)"
        }
    }
}

// MARK: - Home Pages
//enum HomeRoute: AppNavigable, MenuItemRepresentable, CaseIterable {
//    case order(OrderRoute)
//    case history(HistoryRoute)
//    case expense(ExpenseRoute)
//    case revenue(RevenueRoute)
//    case settings(SettingsRoute)
//
//    var id: String {
//        switch self {
//        case .order(let route):
//            return "order_\(route.id)"
//        case .history(let route):
//            return "history_\(route.id)"
//        case .expense(let route):
//            return "expense_\(route.id)"
//        case .revenue(let route):
//            return "revenue_\(route.id)"
//        case .settings(let route):
//            return "settings_\(route.id)"
//        }
//    }
//    
//    var title: String {
//        switch self {
//        case .order: return "Đơn hàng"
//        case .history: return "Lịch sử"
//        case .expense: return "Chi phí"
//        case .revenue: return "Doanh thu"
//        case .settings: return "Cài đặt"
//        }
//    }
//    
//    var themeColor: AppThemeColorEnum {
//        switch self {
//        case .order: return .order
//        case .history: return .history
//        case .expense: return .expense
//        case .revenue: return .revenue
//        case .settings: return .settings
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .order: return "cart.fill"
//        case .history: return "clock.fill"
//        case .expense: return "minus.circle.fill"
//        case .revenue: return "plus.circle.fill"
//        case .settings: return "gear.fill"
//        }
//    }
//    
//    // MARK: - Helper Methods
//    static var mainRoutes: [HomeRoute] {
//        [
//            .order(.main),
//            .history(.main),
//            .expense(.main),
//            .revenue(.main),
//            .settings(.main)
//        ]
//    }
//    
//    // MARK: - Equatable
//    static func == (lhs: HomeRoute, rhs: HomeRoute) -> Bool {
//        switch (lhs, rhs) {
//        case (.order, .order),
//             (.history, .history),
//             (.expense, .expense),
//             (.revenue, .revenue),
//             (.settings, .settings):
//            return true
//        default:
//            return false
//        }
//    }
//    
//    // MARK: - Theme Colors
//    func resolveThemeColors(from style: AppThemeStyle) -> TabThemeColor {
//        return themeColor.resolve(from: style.colors)
//    }
//    
//    var currentThemeColors: TabThemeColor {
//        return resolveThemeColors(from: SettingsService.shared.currentThemeStyle)
//    }
//}
