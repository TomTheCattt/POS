//
//  StorageService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI
import FirebaseStorage

final class StorageService: StorageServiceProtocol {
    
    static let shared = StorageService()
    private let storage = Storage.storage()
    
    func uploadImage(_ imageData: Data, path: String) async throws -> URL {
        let storageRef = storage.reference()
        let imageRef = storageRef.child(path)
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            return downloadURL
        } catch {
            throw StorageError.uploadFailed
        }
    }
    
    func deleteImage(at url: URL) async throws {
        guard let path = url.path.removingPercentEncoding else {
            throw StorageError.fileNotFound
        }
        
        let storageRef = storage.reference()
        let imageRef = storageRef.child(path)
        
        do {
            try await imageRef.delete()
        } catch {
            throw StorageError.permissionDenied
        }
    }
}
