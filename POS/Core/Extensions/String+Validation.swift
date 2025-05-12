//
//  String+Validation.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

final class ValidationLocalizedString {
    let authErrorEmptyDisplayName = NSLocalizedString("error.auth.empty_display_name", comment: "")
    let authErrorEmptyShopName = NSLocalizedString("error.auth.empty_shop_name", comment: "")
    let authErrorEmptyEmail = NSLocalizedString("error.auth.empty_email", comment: "")
    let authErrorEmptyPassword = NSLocalizedString("error.auth.empty_password", comment: "")
    let authErrorValidatePasswordFailed = NSLocalizedString("error.auth.validate_password_failed", comment: "")
    let authErrorReEnterPasswordEmpty = NSLocalizedString("error.auth.re_enter_password_empty", comment: "")
    let authErrorEmailInUse = NSLocalizedString("error.auth.email_in_use", comment: "")
    let authErrorInvalidEmail = NSLocalizedString("error.auth.invalid_email", comment: "")
    let authErrorTooManyRequest = NSLocalizedString("error.auth.too_many_requests", comment: "")
    let authErrorUnknown = NSLocalizedString("error.auth.unknown", comment: "")
    let authErrorUserNotFound = NSLocalizedString("error.auth.user_not_found", comment: "")
    let authErrorWrongPassword = NSLocalizedString("error.auth.wrong_password", comment: "")
    let authErrorShopNotFound = NSLocalizedString("error.auth.shop_not_found", comment: "")
    let authErrorEmailNotFound = NSLocalizedString("error.auth.email_not_found", comment: "")
    let verifyEmailSent = NSLocalizedString("verify_email_sent", comment: "")
    let verifyEmailSentContent = NSLocalizedString("verify_email_sent_content", comment: "")
    let emailVerified = NSLocalizedString("email_verified", comment: "")
}
