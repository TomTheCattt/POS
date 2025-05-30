//
//  CrashlyticsService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseCrashlytics

final class CrashlyticsService: CrashlyticsServiceProtocol {
    
    static let shared = CrashlyticsService()
    private let crashlytics = Crashlytics.crashlytics()
    
    private init() {}

    func log(_ message: String) {
        crashlytics.log(message)
    }

    func record(error: Error) {
        crashlytics.record(error: error)
    }

    func setUserID(_ id: String) {
        crashlytics.setUserID(id)
    }
    
    deinit {
        // Cleanup any resources if needed
    }
}

