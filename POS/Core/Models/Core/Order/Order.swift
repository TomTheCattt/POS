//
//  Order.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Tiền mặt"
    case card = "Thẻ"
    case bankTransfer = "Chuyển khoản"
    
    var icon: String {
        switch self {
        case .cash:
            return "banknote.fill"
        case .card:
            return "creditcard.fill"
        case .bankTransfer:
            return "iphone"
        }
    }
    
    var title: String {
        switch self {
        case .cash:
            return "Tiền mặt"
        case .card:
            return "Thẻ"
        case .bankTransfer:
            return "Chuyển khoản"
        }
    }
    
    var description: String {
        switch self {
        case .cash:
            return "Thanh toán khi nhận hàng"
        case .card:
            return "Thẻ tín dụng/ghi nợ"
        case .bankTransfer:
            return "Chuyển khoản ngân hàng"
        }
    }
    
    var color: Color {
        switch self {
        case .cash: return .green
        case .card: return .blue
        case .bankTransfer: return .purple
        }
    }
}

enum TemperatureOption: String, CaseIterable, Codable {
    case hot = "Nóng"
    case cold = "Lạnh"
    
    var icon: String {
        switch self {
        case .hot: return "flame"
        case .cold: return "snowflake"
        }
    }
}

enum ConsumptionOption: String, CaseIterable, Codable {
    case stay = "Tại chỗ"
    case takeAway = "Mang đi"
    
    var icon: String {
        switch self {
        case .stay: return "house"
        case .takeAway: return "bag"
        }
    }
}

struct Order: Codable, Identifiable, Hashable {
    // MARK: - Properties
    @DocumentID var id: String?
    let shopId: String
    let items: [OrderItem]
    let discount: Double?
    let totalAmount: Double
    let paymentMethod: PaymentMethod
    let customer: Customer?
    let createdAt: Date
    var updatedAt: Date
    let createdBy: String? // Staff ID who created the order
    let notes: String? // Additional notes for the order

    // MARK: - Computed Properties
    var formattedId: String {
        if let id = id {
            let shortId = String(id.suffix(6)).uppercased()
            return "#\(shortId)"
        }
        return "#N/A"
    }
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }
    
    var discountAmount: Double {
        discount ?? 0
    }
    
    var finalTotal: Double {
        subtotal - discountAmount
    }
    
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: finalTotal)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    var formattedSubtotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: subtotal)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    var formattedDiscount: String {
        guard let discount = discount, discount > 0 else { return "0đ" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: discount)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        shopId: String,
        items: [OrderItem],
        discount: Double? = nil,
        totalAmount: Double,
        paymentMethod: PaymentMethod,
        customer: Customer? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        createdBy: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.shopId = shopId
        self.items = items
        self.discount = discount
        self.totalAmount = totalAmount
        self.paymentMethod = paymentMethod
        self.customer = customer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.notes = notes
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "shopId": shopId,
            "items": items.map { $0.dictionary },
            "totalAmount": totalAmount,
            "paymentMethod": paymentMethod.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let discount = discount {
            dict["discount"] = discount
        }
        
        if let customer = customer {
            dict["customer"] = customer.dictionary
        }
        
        if let createdBy = createdBy {
            dict["createdBy"] = createdBy
        }
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let shopId = dictionary["shopId"] as? String,
              let itemsArray = dictionary["items"] as? [[String: Any]],
              let totalAmount = dictionary["totalAmount"] as? Double,
              let paymentMethodRaw = dictionary["paymentMethod"] as? String,
              let paymentMethod = PaymentMethod(rawValue: paymentMethodRaw),
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        // Parse OrderItems
        let items = itemsArray.compactMap { OrderItem(dictionary: $0) }
        guard !items.isEmpty else { return nil }
        
        // Parse Customer
        var customer: Customer?
        if let customerDict = dictionary["customer"] as? [String: Any] {
            customer = Customer(dictionary: customerDict)
        }
        
        self.init(
            shopId: shopId,
            items: items,
            discount: dictionary["discount"] as? Double,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            customer: customer,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            createdBy: dictionary["createdBy"] as? String,
            notes: dictionary["notes"] as? String
        )
    }
    
    // MARK: - Mutating Methods
    
    mutating func addItem(_ item: OrderItem) {
        // Note: This would need to be handled in the view model since structs are value types
        // This is just for reference
        updatedAt = Date()
    }
    
    mutating func removeItem(at index: Int) {
        // Note: This would need to be handled in the view model since structs are value types
        // This is just for reference
        updatedAt = Date()
    }
    
    mutating func updateDiscount(_ newDiscount: Double?) {
        // Note: This would need to be handled in the view model since structs are value types
        // This is just for reference
        updatedAt = Date()
    }
    
    // MARK: - Helper Methods
    func calculateTotal() -> Double {
        let subtotal = items.reduce(0) { $0 + $1.subtotal }
        let discountAmount = discount ?? 0
        return subtotal - discountAmount
    }
    
    func getItemsByCategory() -> [String: [OrderItem]] {
        Dictionary(grouping: items) { $0.category }
    }
    
    func getTopSellingItems() -> [(name: String, quantity: Int)] {
        let itemCounts = items.reduce(into: [String: Int]()) { result, item in
            result[item.name, default: 0] += item.quantity
        }
        return itemCounts.sorted { $0.value > $1.value }.map { (name: $0.key, quantity: $0.value) }
    }
}

struct OrderItem: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Properties
    let id: String
    let menuItemId: String
    let name: String
    var quantity: Int
    let price: Double
    var note: String?
    let temperature: TemperatureOption
    let consumption: ConsumptionOption
    let category: String
    let createdAt: Date

    // MARK: - Computed Properties
    var subtotal: Double {
        price * Double(quantity)
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: price)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    var formattedSubtotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: subtotal)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        menuItemId: String,
        name: String,
        quantity: Int,
        price: Double,
        note: String? = nil,
        temperature: TemperatureOption = .hot,
        consumption: ConsumptionOption = .stay,
        category: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.name = name
        self.quantity = quantity
        self.price = price
        self.note = note
        self.temperature = temperature
        self.consumption = consumption
        self.category = category
        self.createdAt = createdAt
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "menuItemId": menuItemId,
            "name": name,
            "quantity": quantity,
            "price": price,
            "temperature": temperature.rawValue,
            "consumption": consumption.rawValue,
            "category": category,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let note = note {
            dict["note"] = note
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let menuItemId = dictionary["menuItemId"] as? String,
              let name = dictionary["name"] as? String,
              let quantity = dictionary["quantity"] as? Int,
              let price = dictionary["price"] as? Double,
              let temperatureRaw = dictionary["temperature"] as? String,
              let temperature = TemperatureOption(rawValue: temperatureRaw),
              let consumptionRaw = dictionary["consumption"] as? String,
              let consumption = ConsumptionOption(rawValue: consumptionRaw),
              let category = dictionary["category"] as? String,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.init(
            id: id,
            menuItemId: menuItemId,
            name: name,
            quantity: quantity,
            price: price,
            note: dictionary["note"] as? String,
            temperature: temperature,
            consumption: consumption,
            category: category,
            createdAt: createdAtTimestamp.dateValue()
        )
    }
    
    // MARK: - Mutating Methods
    mutating func updateQuantity(_ newQuantity: Int) {
        quantity = max(1, newQuantity)
    }
    
    mutating func updateNote(_ newNote: String?) {
        note = newNote
    }
    
    mutating func updateTemperature(_ newTemperature: TemperatureOption) {
        // Note: This would need to be handled in the view model since structs are value types
        // This is just for reference
    }
    
    mutating func updateConsumption(_ newConsumption: ConsumptionOption) {
        // Note: This would need to be handled in the view model since structs are value types
        // This is just for reference
    }
}

// MARK: - Order Extensions
extension Order {
    enum ValidationError: LocalizedError {
        case emptyItems
        case invalidTotalAmount
        case invalidDiscount
        case invalidCustomer
        case invalidPaymentMethod
        
        var errorDescription: String? {
            switch self {
            case .emptyItems:
                return "Đơn hàng phải có ít nhất một món"
            case .invalidTotalAmount:
                return "Tổng tiền không hợp lệ"
            case .invalidDiscount:
                return "Giảm giá không hợp lệ"
            case .invalidCustomer:
                return "Thông tin khách hàng không hợp lệ"
            case .invalidPaymentMethod:
                return "Phương thức thanh toán không hợp lệ"
            }
        }
    }
    
    func validate() throws {
        // Validate items
        guard !items.isEmpty else {
            throw ValidationError.emptyItems
        }
        
        // Validate total amount
        guard totalAmount >= 0 else {
            throw ValidationError.invalidTotalAmount
        }
        
        // Validate discount
        if let discount = discount {
            guard discount >= 0 && discount <= subtotal else {
                throw ValidationError.invalidDiscount
            }
        }
        
        // Validate payment method
        guard PaymentMethod.allCases.contains(paymentMethod) else {
            throw ValidationError.invalidPaymentMethod
        }
    }
    
    static func createOrder(
        shopId: String,
        items: [OrderItem],
        discount: Double? = nil,
        paymentMethod: PaymentMethod,
        customer: Customer? = nil,
        createdBy: String? = nil,
        notes: String? = nil
    ) throws -> Order {
        // Validate items
        guard !items.isEmpty else {
            throw ValidationError.emptyItems
        }
        
        // Calculate total
        let subtotal = items.reduce(0) { $0 + $1.subtotal }
        let discountAmount = discount ?? 0
        let totalAmount = subtotal - discountAmount
        
        // Validate discount
        if let discount = discount {
            guard discount >= 0 && discount <= subtotal else {
                throw ValidationError.invalidDiscount
            }
        }
        
        return Order(
            shopId: shopId,
            items: items,
            discount: discount,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            customer: customer,
            createdBy: createdBy,
            notes: notes
        )
    }
}
