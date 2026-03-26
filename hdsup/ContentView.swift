//
//  ContentView.swift
//  hdsup
//
//  Created by Michel Mainville on 2026-03-25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingPluginManager = false
    
    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("Heads-Up Display")
                .font(.title)
                .fontWeight(.bold)

            ToggleImmersiveSpaceButton()
            
            // Plugin Manager Button
            Button {
                showingPluginManager = true
            } label: {
                Label("Manage Plugins", systemImage: "puzzlepiece.extension.fill")
            }
            .buttonStyle(.borderedProminent)
            
            // HUD Controls
            VStack(spacing: 12) {
                Toggle("Top Ornament", isOn: Bindable(appModel).showTopOrnament)
                Toggle("Bottom Ornament", isOn: Bindable(appModel).showBottomOrnament)
                Toggle("Side Ornaments", isOn: Bindable(appModel).showSideOrnaments)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .sheet(isPresented: $showingPluginManager) {
            PluginManagementView()
        }
        // Top ornament - displays first data source
        .ornament(
            visibility: appModel.showTopOrnament ? .visible : .hidden,
            attachmentAnchor: .scene(.top)
        ) {
            if let firstSource = appModel.hudDataService.dataSources.first,
               let data = appModel.hudDataService.getData(for: firstSource.id) {
                HUDOrnamentView(data: data, style: .compact)
            } else {
                HUDOrnamentView(
                    data: HUDData(title: "Waiting", value: "...", unit: nil),
                    style: .minimal
                )
            }
        }
        // Bottom ornament - displays detailed view
        .ornament(
            visibility: appModel.showBottomOrnament ? .visible : .hidden,
            attachmentAnchor: .scene(.bottom)
        ) {
            if let sources = appModel.hudDataService.dataSources.first,
               let data = appModel.hudDataService.getData(for: sources.id) {
                HUDOrnamentView(data: data, style: .detailed)
            } else {
                Text("Loading data...")
                    .font(.caption)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        // Leading ornament
        .ornament(
            visibility: appModel.showSideOrnaments ? .visible : .hidden,
            attachmentAnchor: .scene(.leading)
        ) {
            VStack(spacing: 8) {
                ForEach(Array(appModel.hudDataService.dataSources.prefix(3)), id: \.id) { source in
                    if let data = appModel.hudDataService.getData(for: source.id) {
                        HUDOrnamentView(data: data, style: .minimal)
                    }
                }
            }
        }
        // Notification ornament - displays active notifications
        .ornament(
            visibility: appModel.showNotifications ? .visible : .hidden,
            attachmentAnchor: .scene(.trailing)
        ) {
            VStack(spacing: 8) {
                ForEach(appModel.notificationService.getActiveNotifications(for: .ornament)) { active in
                    OrnamentNotificationView(
                        active: active,
                        onDismiss: {
                            appModel.notificationService.dismissNotification(id: active.id)
                        },
                        onAction: { action in
                            handleNotificationAction(action)
                        }
                    )
                }
            }
        }
        .task {
            // Start auto-updating data when view appears
            await appModel.hudDataService.updateAllData()
            appModel.hudDataService.startAutoUpdate(interval: 30)
            
            // Start webhook server for notifications
            appModel.notificationService.startWebhookServer()
        }
        .onDisappear {
            appModel.notificationService.stopWebhookServer()
        }
    }
    
    private func handleNotificationAction(_ action: NotificationAction) {
        switch action.type {
        case .openURL:
            if let urlString = action.url, let url = URL(string: urlString) {
                // Open URL (would need to handle this properly in visionOS)
                print("Opening URL: \(url)")
            }
        case .dismiss:
            break
        default:
            print("Action: \(action.title)")
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
