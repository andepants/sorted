/// NetworkMonitor.swift
///
/// Singleton network connectivity monitor using NWPathMonitor.
/// Initialize ONCE in SortedApp.swift, not in individual views.
///
/// Created: 2025-10-21 (Story 2.2 - Pattern 2 from Epic 2)

import Combine
import Foundation
import Network
import SwiftUI

/// Singleton network connectivity monitor
/// Initialize ONCE in SortedApp.swift, inject via `.environmentObject()`
@MainActor
final class NetworkMonitor: ObservableObject {
    /// Shared singleton instance
    static let shared = NetworkMonitor()

    // MARK: - Published Properties

    @Published var isConnected = true
    @Published var isCellular = false
    @Published var isConstrained = false

    // MARK: - Private Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.sorted.networkmonitor")

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isCellular = path.isExpensive
                self?.isConstrained = path.isConstrained
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
