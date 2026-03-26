//
//  NotificationModels.swift
//  hdsup
//
//  Notification webhook system models
//

import Foundation
import SwiftUI

// MARK: - Webhook Notification Format

/// Standard webhook notification payload
struct WebhookNotification: Codable, Identifiable {
    let id: String
    let source: NotificationSource
    let type: NotificationType
    let content: NotificationContent
    let priority: NotificationPriority
    let timestamp: String
    let expiresAt: String?
    let metadata: [String: String]?
    let actions: [NotificationAction]?
}

/// Source application information
struct NotificationSource: Codable {
    let id: String
    let name: String
    let icon: String?
    let category: String
}

/// Type of notification
enum NotificationType: String, Codable {
    case message
    case email
    case alert
    case reminder
    case event
    case call
    case custom
}

/// Notification content
struct NotificationContent: Codable {
    let title: String
    let subtitle: String?
    let body: String?
    let imageURL: String?
    let soundName: String?
    let badge: Int?
}

/// Notification priority
enum NotificationPriority: String, Codable, CaseIterable {
    case low
    case normal
    case high
    case urgent
    
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }
}

/// Interactive action
struct NotificationAction: Codable, Identifiable {
    let id: String
    let title: String
    let type: ActionType
    let url: String?
    let destructive: Bool
    
    enum ActionType: String, Codable {
        case openURL
        case reply
        case dismiss
        case custom
    }
}

// MARK: - Notification Routing

/// How a notification should be presented in the HUD
enum NotificationPresentationStyle: String, Codable, CaseIterable {
    case ornament           // Floating ornament that follows view
    case fixedWidget        // Fixed widget on a wall/surface
    case spatialObject      // 3D object in space (e.g., over a physical object)
    case banner             // Temporary banner notification
    case immersiveAlert     // Full immersive alert
    case badge              // Badge on existing element
    
    var displayName: String {
        switch self {
        case .ornament: return "Floating Ornament"
        case .fixedWidget: return "Fixed Widget"
        case .spatialObject: return "Spatial Object"
        case .banner: return "Banner"
        case .immersiveAlert: return "Immersive Alert"
        case .badge: return "Badge"
        }
    }
    
    var icon: String {
        switch self {
        case .ornament: return "rectangle.and.hand.point.up.left.fill"
        case .fixedWidget: return "rectangle.on.rectangle"
        case .spatialObject: return "cube.fill"
        case .banner: return "bell.badge.fill"
        case .immersiveAlert: return "exclamationmark.triangle.fill"
        case .badge: return "circle.badge.fill"
        }
    }
}

/// Routing rule for notifications
struct NotificationRoutingRule: Codable, Identifiable {
    var id: UUID
    var name: String
    var enabled: Bool
    
    // Matching criteria
    var sourcePattern: String?          // Regex or exact match
    var typeFilter: NotificationType?
    var priorityFilter: NotificationPriority?
    var categoryFilter: String?
    
    // Presentation configuration
    var presentationStyle: NotificationPresentationStyle
    var presentationConfig: PresentationConfiguration
    
    // Spatial configuration (for fixed widgets and spatial objects)
    var spatialConfig: SpatialConfiguration?
    
    // Auto-dismiss configuration
    var autoDismiss: Bool
    var dismissDelay: TimeInterval?
    
    init(
        id: UUID = UUID(),
        name: String,
        enabled: Bool = true,
        sourcePattern: String? = nil,
        typeFilter: NotificationType? = nil,
        priorityFilter: NotificationPriority? = nil,
        categoryFilter: String? = nil,
        presentationStyle: NotificationPresentationStyle,
        presentationConfig: PresentationConfiguration = PresentationConfiguration(),
        spatialConfig: SpatialConfiguration? = nil,
        autoDismiss: Bool = true,
        dismissDelay: TimeInterval? = 10
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.sourcePattern = sourcePattern
        self.typeFilter = typeFilter
        self.priorityFilter = priorityFilter
        self.categoryFilter = categoryFilter
        self.presentationStyle = presentationStyle
        self.presentationConfig = presentationConfig
        self.spatialConfig = spatialConfig
        self.autoDismiss = autoDismiss
        self.dismissDelay = dismissDelay
    }
}

/// Presentation configuration
struct PresentationConfiguration: Codable {
    var size: NotificationSize
    var colorTheme: String?
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var showTimestamp: Bool
    var showSource: Bool
    var showActions: Bool
    
    init(
        size: NotificationSize = .medium,
        colorTheme: String? = nil,
        soundEnabled: Bool = true,
        hapticEnabled: Bool = true,
        showTimestamp: Bool = true,
        showSource: Bool = true,
        showActions: Bool = true
    ) {
        self.size = size
        self.colorTheme = colorTheme
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
        self.showTimestamp = showTimestamp
        self.showSource = showSource
        self.showActions = showActions
    }
}

enum NotificationSize: String, Codable, CaseIterable {
    case small
    case medium
    case large
    
    var displayName: String {
        rawValue.capitalized
    }
}

/// Spatial configuration for positioning notifications
struct SpatialConfiguration: Codable {
    var position: SpatialPosition
    var anchorType: AnchorType
    var offset: SpatialOffset
    var scale: Double
    
    enum SpatialPosition: String, Codable {
        case fixed      // Fixed world position
        case tracked    // Track a physical object
        case relative   // Relative to user
    }
    
    enum AnchorType: String, Codable {
        case world
        case plane
        case image
        case object
        case face
    }
    
    init(
        position: SpatialPosition = .fixed,
        anchorType: AnchorType = .world,
        offset: SpatialOffset = SpatialOffset(),
        scale: Double = 1.0
    ) {
        self.position = position
        self.anchorType = anchorType
        self.offset = offset
        self.scale = scale
    }
}

struct SpatialOffset: Codable {
    var x: Double
    var y: Double
    var z: Double
    
    init(x: Double = 0, y: Double = 1.5, z: Double = -2) {
        self.x = x
        self.y = y
        self.z = z
    }
}

// MARK: - Active Notifications

/// Active notification in the HUD
@Observable
class ActiveNotification: Identifiable {
    let id: String
    let notification: WebhookNotification
    let rule: NotificationRoutingRule
    let receivedAt: Date
    var dismissed: Bool = false
    var dismissedAt: Date?
    var userInteracted: Bool = false
    
    init(notification: WebhookNotification, rule: NotificationRoutingRule) {
        self.id = notification.id
        self.notification = notification
        self.rule = rule
        self.receivedAt = Date()
    }
    
    func dismiss() {
        dismissed = true
        dismissedAt = Date()
    }
    
    var isExpired: Bool {
        if let expiresAt = notification.expiresAt,
           let expireDate = ISO8601DateFormatter().date(from: expiresAt) {
            return Date() > expireDate
        }
        return false
    }
}

// MARK: - Notification Statistics

struct NotificationStatistics: Codable {
    var totalReceived: Int = 0
    var totalDismissed: Int = 0
    var bySource: [String: Int] = [:]
    var byType: [String: Int] = [:]
    var byPriority: [String: Int] = [:]
    var averageResponseTime: TimeInterval = 0
    
    mutating func recordNotification(_ notification: WebhookNotification) {
        totalReceived += 1
        bySource[notification.source.id, default: 0] += 1
        byType[notification.type.rawValue, default: 0] += 1
        byPriority[notification.priority.rawValue, default: 0] += 1
    }
    
    mutating func recordDismissal(responseTime: TimeInterval) {
        totalDismissed += 1
        // Calculate rolling average
        let totalResponseTime = averageResponseTime * Double(totalDismissed - 1) + responseTime
        averageResponseTime = totalResponseTime / Double(totalDismissed)
    }
}

// MARK: - Default Rules

extension NotificationRoutingRule {
    static let defaultRules: [NotificationRoutingRule] = [
        // iMessage notifications appear as spatial objects near phone location
        NotificationRoutingRule(
            name: "iMessage",
            sourcePattern: "^com\\.apple\\.messages",
            typeFilter: .message,
            presentationStyle: .spatialObject,
            presentationConfig: PresentationConfiguration(
                size: .medium,
                colorTheme: "blue"
            ),
            spatialConfig: SpatialConfiguration(
                position: .tracked,
                anchorType: .object,
                offset: SpatialOffset(x: 0, y: 0.2, z: 0)
            ),
            dismissDelay: 30
        ),
        
        // Email notifications as fixed widgets on wall
        NotificationRoutingRule(
            name: "Email",
            typeFilter: .email,
            presentationStyle: .fixedWidget,
            presentationConfig: PresentationConfiguration(
                size: .large,
                showActions: true
            ),
            spatialConfig: SpatialConfiguration(
                position: .fixed,
                anchorType: .plane,
                offset: SpatialOffset(x: 1.5, y: 1.5, z: -2)
            ),
            autoDismiss: false
        ),
        
        // Urgent alerts as immersive
        NotificationRoutingRule(
            name: "Urgent Alerts",
            priorityFilter: .urgent,
            presentationStyle: .immersiveAlert,
            presentationConfig: PresentationConfiguration(
                size: .large,
                hapticEnabled: true
            ),
            autoDismiss: false
        ),
        
        // Normal notifications as banners
        NotificationRoutingRule(
            name: "Default Banners",
            presentationStyle: .banner,
            presentationConfig: PresentationConfiguration(
                size: .small
            ),
            dismissDelay: 5
        )
    ]
}
