//
//  String+Validation.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

final class ValidationLocalizedString {
    static let authErrorEmptyDisplayName = NSLocalizedString("error.auth.empty_display_name", comment: "")
    static let authErrorEmptyShopName = NSLocalizedString("error.auth.empty_shop_name", comment: "")
    static let authErrorEmptyEmail = NSLocalizedString("error.auth.empty_email", comment: "")
    static let authErrorEmptyPassword = NSLocalizedString("error.auth.empty_password", comment: "")
    static let authErrorValidatePasswordFailed = NSLocalizedString("error.auth.validate_password_failed", comment: "")
    static let authErrorReEnterPasswordEmpty = NSLocalizedString("error.auth.re_enter_password_empty", comment: "")
    static let authErrorEmailInUse = NSLocalizedString("error.auth.email_in_use", comment: "")
    static let authErrorInvalidEmail = NSLocalizedString("error.auth.invalid_email", comment: "")
    static let authErrorTooManyRequest = NSLocalizedString("error.auth.too_many_requests", comment: "")
    static let authErrorUnknown = NSLocalizedString("error.auth.unknown", comment: "")
    static let authErrorUserNotFound = NSLocalizedString("error.auth.user_not_found", comment: "")
    static let authErrorWrongPassword = NSLocalizedString("error.auth.wrong_password", comment: "")
    static let authErrorShopNotFound = NSLocalizedString("error.auth.shop_not_found", comment: "")
    static let authErrorEmailNotFound = NSLocalizedString("error.auth.email_not_found", comment: "")
    static let verifyEmailSent = NSLocalizedString("verify_email_sent", comment: "")
    static let verifyEmailSentContent = NSLocalizedString("verify_email_sent_content", comment: "")
    static let emailVerified = NSLocalizedString("email_verified", comment: "")
}
