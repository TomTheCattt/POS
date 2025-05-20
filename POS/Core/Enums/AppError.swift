//
//  AppError.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseAuth
import FirebaseCrashlytics

private let appStrings = AppLocalizedString()
private let validationStrings = ValidationLocalizedString()

// MARK: - Tổng hợp lỗi toàn app
enum AppError: LocalizedError {
    case auth(FirebaseAuthError)
    case network(NetworkError)
    case database(DatabaseError)
    case validation(ValidationError)
    case shop(ShopError)
    case order(OrderError)
    case inventory(InventoryError)
    case unknown
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case disconnected
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case encodingError
    case timeout
    case cancelled
    case unknown(Error)

    var localizedDescription: String {
        switch self {
        case .disconnected:
            return "Không có kết nối Internet."
        case .invalidURL:
            return "URL không hợp lệ."
        case .invalidResponse:
            return "Phản hồi từ máy chủ không hợp lệ."
        case .httpError(let statusCode):
            return "Lỗi HTTP với mã trạng thái: \(statusCode)"
        case .decodingError:
            return "Không thể giải mã dữ liệu từ máy chủ."
        case .encodingError:
            return "Không thể mã hóa dữ liệu gửi đi."
        case .timeout:
            return "Yêu cầu bị hết thời gian chờ."
        case .cancelled:
            return "Yêu cầu đã bị huỷ."
        case .unknown(let error):
            return "Lỗi không xác định: \(error.localizedDescription)"
        }
    }
}


// MARK: - Database Errors
enum DatabaseError: LocalizedError {
    case invalidData
    case decodingError
    case encodingError
    case documentNotFound
    case permissionDenied
    case writeFailed
    case readFailed
    case deleteFailed
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Dữ liệu không hợp lệ"
        case .decodingError:
            return "Không thể giải mã dữ liệu"
        case .encodingError:
            return "Không thể mã hóa dữ liệu"
        case .documentNotFound:
            return "Không tìm thấy tài liệu"
        case .permissionDenied:
            return "Không có quyền truy cập"
        case .writeFailed:
            return "Không thể ghi dữ liệu"
        case .readFailed:
            return "Không thể đọc dữ liệu"
        case .deleteFailed:
            return "Không thể xóa dữ liệu"
        case .updateFailed:
            return "Không thể cập nhật dữ liệu"
        }
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError {
    case emptyField(field: String)
    case invalidFormat(field: String, message: String)
    case passwordMismatch
    case passwordTooWeak
    case invalidPhoneNumber
    case invalidPrice
    case invalidQuantity
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "Vui lòng nhập \(field)"
        case .invalidFormat(let field, let message):
            return "\(field) không hợp lệ. \(message)"
        case .passwordMismatch:
            return "Mật khẩu không khớp"
        case .passwordTooWeak:
            return "Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số"
        case .invalidPhoneNumber:
            return "Số điện thoại không hợp lệ"
        case .invalidPrice:
            return "Giá không hợp lệ"
        case .invalidQuantity:
            return "Số lượng không hợp lệ"
        }
    }
}

// MARK: - Shop Errors
enum ShopError: LocalizedError {
    case notFound
    case invalidId
    case updateFailed
    case deleteFailed
    case createFailed
    case decodingError
    case invalidOwner
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Không tìm thấy cửa hàng"
        case .invalidId:
            return "ID cửa hàng không hợp lệ"
        case .updateFailed:
            return "Không thể cập nhật thông tin cửa hàng"
        case .deleteFailed:
            return "Không thể xóa cửa hàng"
        case .createFailed:
            return "Không thể tạo cửa hàng"
        case .decodingError:
            return "Lỗi khi đọc thông tin cửa hàng"
        case .invalidOwner:
            return "Chủ cửa hàng không hợp lệ"
        }
    }
}

// MARK: - Order Errors
enum OrderError: LocalizedError {
    case invalidItems
    case emptyOrder
    case paymentFailed
    case createFailed
    case updateFailed
    case deleteFailed
    case notFound
    case invalidStatus
    
    var errorDescription: String? {
        switch self {
        case .invalidItems:
            return "Các món trong đơn hàng không hợp lệ"
        case .emptyOrder:
            return "Đơn hàng trống"
        case .paymentFailed:
            return "Thanh toán thất bại"
        case .createFailed:
            return "Không thể tạo đơn hàng"
        case .updateFailed:
            return "Không thể cập nhật đơn hàng"
        case .deleteFailed:
            return "Không thể xóa đơn hàng"
        case .notFound:
            return "Không tìm thấy đơn hàng"
        case .invalidStatus:
            return "Trạng thái đơn hàng không hợp lệ"
        }
    }
}

// MARK: - Inventory Errors
enum InventoryError: LocalizedError {
    case insufficientStock
    case invalidQuantity
    case updateFailed
    case createFailed
    case deleteFailed
    case notFound
    case invalidUnit
    
    var errorDescription: String? {
        switch self {
        case .insufficientStock:
            return "Không đủ số lượng trong kho"
        case .invalidQuantity:
            return "Số lượng không hợp lệ"
        case .updateFailed:
            return "Không thể cập nhật kho"
        case .createFailed:
            return "Không thể tạo mặt hàng mới"
        case .deleteFailed:
            return "Không thể xóa mặt hàng"
        case .notFound:
            return "Không tìm thấy mặt hàng"
        case .invalidUnit:
            return "Đơn vị không hợp lệ"
        }
    }
}

extension AppError {
    var errorDescription: String? {
        Crashlytics.crashlytics().record(error: self)

        switch self {
        case .auth(let error):
            return error.localizedDescription
        case .network(let error):
            return error.localizedDescription
        case .database(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .shop(let error):
            return error.localizedDescription
        case .order(let error):
            return error.localizedDescription
        case .inventory(let error):
            return error.localizedDescription
        case .unknown:
            return appStrings.errorUnknown
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
    case invalidCredential
    case networkError
    case tooManyRequests
    case weakPassword
    case operationNotAllowed
    case accountExistsWithDifferentCredential
    case requiresRecentLogin
    case credentialAlreadyInUse
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
        case .invalidCredential: return .invalidCredential
        case .weakPassword: return .weakPassword
        case .operationNotAllowed: return .operationNotAllowed
        case .accountExistsWithDifferentCredential: return .accountExistsWithDifferentCredential
        case .requiresRecentLogin: return .requiresRecentLogin
        case .credentialAlreadyInUse: return .credentialAlreadyInUse
        default: return .unknown
        }
    }
}

extension FirebaseAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return validationStrings.authErrorInvalidEmail
        case .wrongPassword:
            return validationStrings.authErrorWrongPassword
        case .userNotFound:
            return validationStrings.authErrorUserNotFound
        case .emailAlreadyInUse:
            return validationStrings.authErrorEmailInUse
        case .unverifiedEmailResent:
            return validationStrings.verifyEmailSent
        case .networkError:
            return appStrings.errorNetwork
        case .tooManyRequests:
            return validationStrings.authErrorTooManyRequest
        case .weakPassword:
            return validationStrings.authErrorValidatePasswordFailed
        case .operationNotAllowed:
            return appStrings.permissionDenied
        case .accountExistsWithDifferentCredential:
            return validationStrings.authErrorEmailInUse
        case .requiresRecentLogin:
            return validationStrings.authErrorValidatePasswordFailed
        case .credentialAlreadyInUse:
            return validationStrings.authErrorEmailInUse
        case .unknown:
            return validationStrings.authErrorUnknown
        case .unverifiedEmail:
            return validationStrings.verifyEmailSent
        case .tokenError:
            return validationStrings.authErrorUnknown
        case .invalidCredential:
            return validationStrings.authErrorValidatePasswordFailed
        }
    }
}

// MARK: - Firestore Error
enum FirestoreError: Error {
    case documentNotFound
    case encodingFailed
    case decodingFailed
    case permissionDenied
    case networkError
    case unknown
}

extension FirestoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return appStrings.firestoreErrorNotFound
        case .encodingFailed:
            return appStrings.firestoreErrorUnknown
        case .decodingFailed:
            return appStrings.firestoreErrorDecoding
        case .permissionDenied:
            return appStrings.firestoreErrorPermission
        case .networkError:
            return appStrings.errorNetwork
        case .unknown:
            return appStrings.firestoreErrorUnknown
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
        case .uploadFailed:
            return appStrings.storageErrorUploadFailed
        case .downloadFailed:
            return appStrings.storageErrorDownloadFailed
        case .fileNotFound:
            return appStrings.storageErrorFileNotFound
        case .permissionDenied:
            return appStrings.storageErrorPermission
        case .unknown:
            return appStrings.storageErrorUnknown
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
        case .timeout:
            return appStrings.functionsErrorTimeOut
        case .internalError:
            return appStrings.functionsErrorInternal
        case .invalidArgument:
            return appStrings.functionsErrorInvalidArgument
        case .unknown:
            return appStrings.functionsErrorUnknown
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
        case .tokenFetchFailed:
            return appStrings.messagingErrorTokenFailed
        case .permissionDenied:
            return appStrings.messagingErrorPermission
        case .unknown:
            return appStrings.messagingErrorUnknown
        }
    }
}
