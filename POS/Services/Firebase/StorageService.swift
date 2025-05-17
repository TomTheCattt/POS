//
//  StorageService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI

final class StorageService: StorageServiceProtocol {
    
    static let shared = StorageService()
    
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<URL, AppError>) -> Void) {
        
    }
    
    func deleteImage(at path: String, completion: @escaping (Result<Void, AppError>) -> Void) {
        
    }
    
    
}
