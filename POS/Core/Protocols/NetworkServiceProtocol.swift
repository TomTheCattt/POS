import Foundation
import Combine

protocol NetworkServiceProtocol {
    // HTTP Methods
    func get<T: Decodable>(from url: URL) async throws -> T
    func post<T: Codable>(to url: URL, body: T) async throws
    func put<T: Codable>(to url: URL, body: T) async throws
    func delete(at url: URL) async throws
    
    // Upload/Download
    func upload(data: Data, to url: URL, mimeType: String) async throws -> URL
    func download(from url: URL) async throws -> Data
    
    // Multipart
    func uploadMultipart(
        data: [String: Any],
        files: [String: Data],
        to url: URL
    ) async throws -> Data
    
    // WebSocket
    func connectWebSocket(to url: URL) -> AnyPublisher<WebSocketEvent, Error>
    func sendWebSocketMessage(_ message: String)
    func disconnectWebSocket()
    
    // Network Monitoring
    var isConnected: Bool { get }
    var networkType: NetworkType { get }
    var connectionPublisher: AnyPublisher<NetworkStatus, Never> { get }
}

// MARK: - Supporting Types
enum WebSocketEvent {
    case connected
    case disconnected(Error?)
    case message(String)
    case data(Data)
}

enum NetworkType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

enum NetworkStatus {
    case connected(NetworkType)
    case disconnected
} 