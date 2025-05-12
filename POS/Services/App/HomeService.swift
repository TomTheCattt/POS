//
//  HomeService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 8/5/25.
//

import Foundation
import FirebaseAuth

final class HomeService: HomeServiceProtocol {
    
    private let auth = Auth.auth()
    
    func logout() {
        try? auth.signOut()
    }
}
