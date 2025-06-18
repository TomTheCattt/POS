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
            
            return try await withCheckedThrowingContinuation { continuation in
                let uploadTask = imageRef.putData(imageData, metadata: metadata) { metadata, error in
                    if let _ = error {
                        continuation.resume(throwing: StorageError.uploadFailed)
                        return
                    }
                    
                    imageRef.downloadURL { url, error in
                        if let _ = error {
                            continuation.resume(throwing: StorageError.downloadFailed)
                            return
                        }
                        
                        guard let downloadURL = url else {
                            continuation.resume(throwing: StorageError.downloadFailed)
                            return
                        }
                        
                        continuation.resume(returning: downloadURL)
                    }
                }
                
                uploadTask.observe(.failure) { _ in
                    continuation.resume(throwing: StorageError.uploadFailed)
                }
            }
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
        
        return try await withCheckedThrowingContinuation { continuation in
            imageRef.delete { error in
                if let _ = error {
                    continuation.resume(throwing: StorageError.permissionDenied)
                    return
                }
                continuation.resume()
            }
        }
    }
}
