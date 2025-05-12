//
//  ConectivityMonitor.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import Network

final class ConnectivityMonitor: ObservableObject {
    @Published var isOnline: Bool = true
    private var monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
