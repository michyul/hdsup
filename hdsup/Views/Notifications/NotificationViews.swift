//
//  NotificationViews.swift
//  hdsup
//
//  Notification presentation views for different styles
//

import SwiftUI

// MARK: - Banner Notification

struct BannerNotificationView: View {
    let active: ActiveNotification
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -200
    
    var body: some View {
        HStack(spacing: 12) {
            // Source icon
            if active.rule.presentationConfig.showSource,
               let icon = active.notification.source.icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 40, height: 40)
                    .background(.blue.opacity(0.2), in: Circle())
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(active.notification.content.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if let subtitle = active.notification.content.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if active.rule.presentationConfig.showTimestamp {
                    Text(active.receivedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Dismiss button
            Button {
                withAnimation {
                    offset = -200
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring()) {
                offset = 0
            }
        }
    }
}

// MARK: - Ornament Notification

struct OrnamentNotificationView: View {
    let active: ActiveNotification
    let onDismiss: () -> Void
    let onAction: (NotificationAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if active.rule.presentationConfig.showSource {
                    VStack(alignment: .leading, spacing: 2) {
                        if let icon = active.notification.source.icon {
                            Image(systemName: icon)
                                .foregroundStyle(.blue)
                        }
                        Text(active.notification.source.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                PriorityBadge(priority: active.notification.priority)
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Title and content
            VStack(alignment: .leading, spacing: 8) {
                Text(active.notification.content.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let subtitle = active.notification.content.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let body = active.notification.content.body {
                    Text(body)
                        .font(.body)
                        .lineLimit(3)
                }
            }
            
            // Timestamp
            if active.rule.presentationConfig.showTimestamp {
                Text(active.receivedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Actions
            if active.rule.presentationConfig.showActions,
               let actions = active.notification.actions {
                HStack(spacing: 8) {
                    ForEach(actions) { action in
                        Button {
                            onAction(action)
                        } label: {
                            Text(action.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .tint(action.destructive ? .red : .blue)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: notificationWidth)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 15)
    }
    
    private var notificationWidth: CGFloat {
        switch active.rule.presentationConfig.size {
        case .small: return 250
        case .medium: return 350
        case .large: return 450
        }
    }
}

// MARK: - Supporting Views

struct PriorityBadge: View {
    let priority: NotificationPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(priority.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch priority {
        case .low: return "arrow.down.circle.fill"
        case .normal: return "circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch priority {
        case .low: return .gray.opacity(0.2)
        case .normal: return .blue.opacity(0.2)
        case .high: return .orange.opacity(0.2)
        case .urgent: return .red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch priority {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}
