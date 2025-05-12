//
//  Customer.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/4/25.
//

import Foundation

struct Customer: Codable, Identifiable {
    var id: String
    var name: String
    var phoneNumber: String
    var point: Double
}

