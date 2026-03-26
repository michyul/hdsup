//
//  NotificationService.swift
//  hdsup
//
//  Webhook receiver and notification routing service
//

import Foundation
import Observation
import Network
import SwiftUI

@MainActor
@Observable
class NotificationService {
    // Active notifications
    var activeNotifications: [ActiveNotification] = []
    
    // Routing rules
    var routingRules: [NotificationRoutingRule] = []
    
    // Notification history
    var notificationHistory: [WebhookNotification] = []
    var maxHistorySize: Int = 100
    
    // Statistics
    var statistics = NotificationStatistics()
    
    // Webhook server
    private var webhookServer: WebhookServer?
    var isWebhookServerRunning: Bool = false
    var webhookServerPort: UInt16 = 8080
    var webhookURL: String {
        "http://\(getLocalIPAddress()):\(webhookServerPort)/webhook"
    }
    
    // Settings
    private let userDefaults = UserDefaults.standard
    private let rulesKey = "notification_routing_rules"
    private let statsKey = "notification_statistics"
    
    init() {
        loadRoutingRules()
        loadStatistics()
    }
    
    // MARK: - Webhook Server Management
    
    func startWebhookServer() {
        guard !isWebhookServerRunning else { return }
        
        webhookServer = WebhookServer(port: webhookServerPort) { [weak self] notification in
            await self?.receiveNotification(notification)
        }
        
        webhookServer?.start()
        isWebhookServerRunning = true
    }
    
    func stopWebhookServer() {
        webhookServer?.stop()
        webhookServer = nil
        isWebhookServerRunning = false
    }
    
    // MARK: - Notification Reception
    
    func receiveNotification(_ notification: WebhookNotification) {
        // Add to history
        addToHistory(notification)
        
        // Update statistics
        statistics.recordNotification(notification)
        saveStatistics()
        
        // Find matching rule
        guard let rule = findMatchingRule(for: notification) else {
            print("No matching rule for notification: \(notification.id)")
            return
        }
        
        guard rule.enabled else {
            print("Matching rule disabled: \(rule.name)")
            return
        }
        
        // Create active notification
        let active = ActiveNotification(notification: notification, rule: rule)
        activeNotifications.append(active)
        
        // Play sound if enabled
        if rule.presentationConfig.soundEnabled, let soundName = notification.content.soundName {
            playSound(soundName)
        }
        
        // Auto-dismiss if configured
        if rule.autoDismiss, let delay = rule.dismissDelay {
            Task {
                try? await Task.sleep(for: .seconds(delay))
                await dismissNotification(id: notification.id)
            }
        }
    }
    
    // MARK: - Routing Logic
    
    private func findMatchingRule(for notification: WebhookNotification) -> NotificationRoutingRule? {
        // Find first enabled rule that matches
        return routingRules.first { rule in
            guard rule.enabled else { return false }
            
            // Check source pattern
            if let pattern = rule.sourcePattern {
                if pattern.starts(with: "^") {
                    // Regex match
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       regex.firstMatch(in: notification.source.id, range: NSRange(notification.source.id.startIndex..., in: notification.source.id)) == nil {
                        return false
                    }
                } else {
                    // Exact match
                    if notification.source.id != pattern {
                        return false
                    }
                }
            }
            
            // Check type filter
            if let typeFilter = rule.typeFilter, notification.type != typeFilter {
                return false
            }
            
            // Check priority filter
            if let priorityFilter = rule.priorityFilter, notification.priority != priorityFilter {
                return false
            }
            
            // Check category filter
            if let categoryFilter = rule.categoryFilter, notification.source.category != categoryFilter {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Notification Management
    
    func dismissNotification(id: String) {
        if let index = activeNotifications.firstIndex(where: { $0.id == id }) {
            let notification = activeNotifications[index]
            let responseTime = Date().timeIntervalSince(notification.receivedAt)
            
            notification.dismiss()
            statistics.recordDismissal(responseTime: responseTime)
            saveStatistics()
            
            // Remove after brief delay for animation
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                activeNotifications.removeAll { $0.id == id }
            }
        }
    }
    
    func dismissAll() {
        for notification in activeNotifications {
            dismissNotification(id: notification.id)
        }
    }
    
    func getActiveNotifications(for style: NotificationPresentationStyle) -> [ActiveNotification] {
        return activeNotifications.filter { 
            !$0.dismissed && $0.rule.presentationStyle == style 
        }
    }
    
    // MARK: - Routing Rules Management
    
    func addRoutingRule(_ rule: NotificationRoutingRule) {
        routingRules.insert(rule, at: 0) // Insert at beginning for priority
        saveRoutingRules()
    }
    
    func updateRoutingRule(_ rule: NotificationRoutingRule) {
        if let index = routingRules.firstIndex(where: { $0.id == rule.id }) {
            routingRules[index] = rule
            saveRoutingRules()
        }
    }
    
    func deleteRoutingRule(id: UUID) {
        routingRules.removeAll { $0.id == id }
        saveRoutingRules()
    }
    
    func moveRoutingRule(from: IndexSet, to: Int) {
        routingRules.move(fromOffsets: from, toOffset: to)
        saveRoutingRules()
    }
    
    func loadDefaultRules() {
        routingRules = NotificationRoutingRule.defaultRules
        saveRoutingRules()
    }
    
    // MARK: - Persistence
    
    private func saveRoutingRules() {
        if let encoded = try? JSONEncoder().encode(routingRules) {
            userDefaults.set(encoded, forKey: rulesKey)
        }
    }
    
    private func loadRoutingRules() {
        if let data = userDefaults.data(forKey: rulesKey),
           let decoded = try? JSONDecoder().decode([NotificationRoutingRule].self, from: data) {
            routingRules = decoded
        } else {
            // Load defaults on first launch
            loadDefaultRules()
        }
    }
    
    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            userDefaults.set(encoded, forKey: statsKey)
        }
    }
    
    private func loadStatistics() {
        if let data = userDefaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(NotificationStatistics.self, from: data) {
            statistics = decoded
        }
    }
    
    // MARK: - History Management
    
    private func addToHistory(_ notification: WebhookNotification) {
        notificationHistory.insert(notification, at: 0)
        
        // Trim to max size
        if notificationHistory.count > maxHistorySize {
            notificationHistory = Array(notificationHistory.prefix(maxHistorySize))
        }
    }
    
    func clearHistory() {
        notificationHistory.removeAll()
    }
    
    // MARK: - Utilities
    
    private func playSound(_ soundName: String) {
        // TODO: Implement sound playback
        print("Playing sound: \(soundName)")
    }
    
    private func getLocalIPAddress() -> String {
        var address = "localhost"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    if let name = interface?.ifa_name {
                        let interfaceName = String(cString: name)
                        if interfaceName == "en0" { // WiFi interface
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            if getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                         &hostname, socklen_t(hostname.count),
                                         nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                                address = String(cString: hostname)
                            }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
}

// MARK: - Webhook Server

class WebhookServer {
    private let port: UInt16
    private let onNotification: (WebhookNotification) async -> Void
    private var listener: NWListener?
    
    init(port: UInt16, onNotification: @escaping (WebhookNotification) async -> Void) {
        self.port = port
        self.onNotification = onNotification
    }
    
    func start() {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Webhook server listening on port \(self.port)")
                case .failed(let error):
                    print("Webhook server failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: .global())
        } catch {
            print("Failed to start webhook server: \(error)")
        }
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processRequest(data: data, connection: connection)
            }
            
            if isComplete {
                connection.cancel()
            }
        }
    }
    
    private func processRequest(data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }
        
        // Simple HTTP parsing
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first,
              requestLine.contains("POST /webhook") else {
            sendResponse(connection: connection, statusCode: 404, body: "Not Found")
            return
        }
        
        // Find JSON body (after blank line)
        if let bodyStart = request.range(of: "\r\n\r\n")?.upperBound {
            let jsonString = String(request[bodyStart...])
            if let jsonData = jsonString.data(using: .utf8),
               let notification = try? JSONDecoder().decode(WebhookNotification.self, from: jsonData) {
                
                // Process notification
                Task {
                    await self.onNotification(notification)
                }
                
                sendResponse(connection: connection, statusCode: 200, body: "{\"status\":\"received\"}")
                return
            }
        }
        
        sendResponse(connection: connection, statusCode: 400, body: "Invalid JSON")
    }
    
    private func sendResponse(connection: NWConnection, statusCode: Int, body: String) {
        let response = """
        HTTP/1.1 \(statusCode) OK\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        \r
        \(body)
        """
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
