//
//  AuthManager.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 10/5/25.
//

import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    // Sử dụng AppStorage để lưu trữ trạng thái đăng nhập
    @AppStorage("isAuthenticated") private var _isAuthenticated: Bool = false
    @AppStorage("userToken") private var _userToken: String = ""
    
    // Tạo published wrapper cho trạng thái đăng nhập
    var isAuthenticated: Bool {
        get { _isAuthenticated }
        set {
            objectWillChange.send()
            _isAuthenticated = newValue
        }
    }
    
    var userToken: String {
        get { _userToken }
        set {
            objectWillChange.send()
            _userToken = newValue
        }
    }
    
    @Published var currentUser: SessionUser?
    
    init() {
        // Kiểm tra và tải thông tin người dùng nếu đã đăng nhập
        if isAuthenticated && !userToken.isEmpty {
            fetchUserInfo(token: userToken)
        }
    }
    
    func saveToken(_ token: String) {
        userToken = token
        isAuthenticated = true
    }
    
    func logout() {
        userToken = ""
        isAuthenticated = false
        currentUser = nil
    }
    
    private func fetchUserInfo(token: String) {
        // Gọi API để lấy thông tin người dùng
        // Cập nhật currentUser
    }
}
