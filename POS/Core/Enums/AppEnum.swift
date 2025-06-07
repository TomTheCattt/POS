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
