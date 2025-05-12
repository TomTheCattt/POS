//
//  AppError.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseAuth
import FirebaseCrashlytics

// MARK: - Tổng hợp lỗi toàn app
enum AppError: Error {
    case auth(FirebaseAuthError)
    case firestore(FirestoreError)
    case storage(StorageError)
    case functions(FunctionsError)
    case messaging(MessagingError)
    case invalidShopName(reason: String)
    case duplicateShopName(message: String, suggestions: [String])
    case unknown
}


extension AppError: LocalizedError {
    var errorDescription: String? {
        Crashlytics.crashlytics().record(error: self) // Ghi log vào Crashlytics

        switch self {
        case .auth(let error):
            return error.errorDescription
        case .firestore(let error):
            return error.errorDescription
        case .storage(let error):
            return error.errorDescription
        case .functions(let error):
            return error.errorDescription
        case .messaging(let error):
            return error.errorDescription
        case .invalidShopName(let reason):
            return reason
        case .duplicateShopName(let message, _):
            return message
        case .unknown:
            return NSLocalizedString("Đã xảy ra lỗi không xác định.", comment: "")
        }
    }
}


// MARK: - Auth Error
enum FirebaseAuthError: Error {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case unverifiedEmailResent
    case networkError
    case tooManyRequests
    case unknown
    case unverifiedEmail
    case tokenError
}

extension FirebaseAuthError {
    static func map(_ error: Error) -> FirebaseAuthError {
        if let error = error as NSError? {
            print("🔥 Firebase Auth Error - domain: \(error.domain)")
            print("🔥 code: \(error.code)")
            print("🔥 userInfo: \(error.userInfo)")
        }
        guard let code = AuthErrorCode(rawValue: (error as NSError).code) else {
            return .unknown
        }

        switch code {
        case .invalidEmail: return .invalidEmail
        case .wrongPassword: return .wrongPassword
        case .userNotFound: return .userNotFound
        case .emailAlreadyInUse: return .emailAlreadyInUse
        case .networkError: return .networkError
        case .tooManyRequests: return .tooManyRequests
        default: return .unknown
        }
    }
}

extension FirebaseAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidEmail: return NSLocalizedString("error.auth.invalid_email", comment: "")
        case .wrongPassword: return NSLocalizedString("error.auth.wrong_password", comment: "")
        case .userNotFound: return NSLocalizedString("error.auth.user_not_found", comment: "")
        case .emailAlreadyInUse: return NSLocalizedString("error.auth.email_in_use", comment: "")
        case .unverifiedEmailResent: return NSLocalizedString("error.auth.unverified_email_resent", comment: "")
        case .networkError: return NSLocalizedString("error.network", comment: "")
        case .tooManyRequests: return NSLocalizedString("error.auth.too_many_requests", comment: "")
        case .unknown: return NSLocalizedString("error.auth.unknown", comment: "")
        case .unverifiedEmail: return NSLocalizedString("error.auth.unverified_email", comment: "")
        case .tokenError: return " Token Error"
        }
    }
}

// MARK: - Firestore Error
enum FirestoreError: Error {
    case documentNotFound
    case decodingFailed
    case permissionDenied
    case networkError
    case unknown
}

extension FirestoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .documentNotFound: return NSLocalizedString("error.firestore.not_found", comment: "")
        case .decodingFailed: return NSLocalizedString("error.firestore.decoding", comment: "")
        case .permissionDenied: return NSLocalizedString("error.firestore.permission", comment: "")
        case .networkError: return NSLocalizedString("error.network", comment: "")
        case .unknown: return NSLocalizedString("error.firestore.unknown", comment: "")
        }
    }
}

// MARK: - Storage Error
enum StorageError: Error {
    case uploadFailed
    case downloadFailed
    case fileNotFound
    case permissionDenied
    case unknown
}

extension StorageError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .uploadFailed: return NSLocalizedString("error.storage.upload_failed", comment: "")
        case .downloadFailed: return NSLocalizedString("error.storage.download_failed", comment: "")
        case .fileNotFound: return NSLocalizedString("error.storage.file_not_found", comment: "")
        case .permissionDenied: return NSLocalizedString("error.storage.permission", comment: "")
        case .unknown: return NSLocalizedString("error.storage.unknown", comment: "")
        }
    }
}

// MARK: - Functions Error
enum FunctionsError: Error {
    case timeout
    case internalError
    case invalidArgument
    case unknown
}

extension FunctionsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeout: return NSLocalizedString("error.functions.timeout", comment: "")
        case .internalError: return NSLocalizedString("error.functions.internal", comment: "")
        case .invalidArgument: return NSLocalizedString("error.functions.invalid_argument", comment: "")
        case .unknown: return NSLocalizedString("error.functions.unknown", comment: "")
        }
    }
}

// MARK: - Messaging Error
enum MessagingError: Error {
    case tokenFetchFailed
    case permissionDenied
    case unknown
}

extension MessagingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .tokenFetchFailed: return NSLocalizedString("error.messaging.token_failed", comment: "")
        case .permissionDenied: return NSLocalizedString("error.messaging.permission", comment: "")
        case .unknown: return NSLocalizedString("error.messaging.unknown", comment: "")
        }
    }
}
