import Foundation
import Network
import Combine

final class NetworkService: NetworkServiceProtocol {
    // MARK: - Singleton
    static let shared = NetworkService()
    
    // MARK: - Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let session = URLSession.shared
    private var webSocketTask: URLSessionWebSocketTask?
    
    private let connectionSubject = CurrentValueSubject<NetworkStatus, Never>(.disconnected)
    
    var isConnected: Bool {
        monitor.currentPath.status == .satisfied
    }
    
    var networkType: NetworkType {
        if monitor.currentPath.usesInterfaceType(.wifi) {
            return .wifi
        } else if monitor.currentPath.usesInterfaceType(.cellular) {
            return .cellular
        } else if monitor.currentPath.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    var connectionPublisher: AnyPublisher<NetworkStatus, Never> {
        connectionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let status: NetworkStatus
            if path.status == .satisfied {
                status = .connected(self.networkType)
            } else {
                status = .disconnected
            }
            
            DispatchQueue.main.async {
                self.connectionSubject.send(status)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // MARK: - HTTP Methods
    func get<T: Decodable>(from url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(.httpError(statusCode: httpResponse.statusCode))
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.network(.decodingError)
        }
    }
    
    func post<T: Codable>(to url: URL, body: T) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AppError.network(.encodingError)
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(.httpError(statusCode: httpResponse.statusCode))
        }
    }
    
    func put<T: Codable>(to url: URL, body: T) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AppError.network(.encodingError)
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(.httpError(statusCode: httpResponse.statusCode))
        }
    }
    
    func delete(at url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(.httpError(statusCode: httpResponse.statusCode))
        }
    }
    
    // MARK: - Upload/Download
    func upload(data: Data, to url: URL, mimeType: String) async throws -> URL {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(.httpError(statusCode: httpResponse.statusCode))
        }
        
        // Assuming the response contains the URL of the uploaded file
        guard let urlString = String(data: responseData, encoding: .utf8),
              let fileURL = URL(string: urlString) else {
            throw AppError.network(.invalidResponse)
        }
        
        return fileURL
    }
    
    func download(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(.httpError(statusCode: httpResponse.statusCode))
        }
        
        return data
    }
    
    // MARK: - Multipart
    func uploadMultipart(
        data: [String: Any],
        files: [String: Data],
        to url: URL
    ) async throws -> Data {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add form fields
        for (key, value) in data {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        // Add files
        for (key, fileData) in files {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key)\"\r\n")
            body.append("Content-Type: application/octet-stream\r\n\r\n")
            body.append(fileData)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(.httpError(statusCode: httpResponse.statusCode))
        }
        
        return responseData
    }
    
    // MARK: - WebSocket
    func connectWebSocket(to url: URL) -> AnyPublisher<WebSocketEvent, Error> {
        let subject = PassthroughSubject<WebSocketEvent, Error>()
        
        webSocketTask = session.webSocketTask(with: url)
        
        webSocketTask?.resume()
        receiveMessage(subject: subject)
        
        subject.send(.connected)
        
        return subject.eraseToAnyPublisher()
    }
    
    func sendWebSocketMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending WebSocket message: \(error)")
            }
        }
    }
    
    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    // MARK: - Private Methods
    private func receiveMessage(subject: PassthroughSubject<WebSocketEvent, Error>) {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    subject.send(.message(text))
                case .data(let data):
                    subject.send(.data(data))
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMessage(subject: subject)
                
            case .failure(let error):
                subject.send(.disconnected(error))
                subject.send(completion: .failure(error))
            }
        }
    }
}

// MARK: - Data Extensions
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


