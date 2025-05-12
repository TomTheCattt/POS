//
//  CrashlyticsService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseCrashlytics

final class CrashlyticsService: CrashlyticsServiceProtocol {

    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    func record(error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }

    func setUserID(_ id: String) {
        Crashlytics.crashlytics().setUserID(id)
    }
}

