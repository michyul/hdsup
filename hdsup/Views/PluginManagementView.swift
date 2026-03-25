//
//  PluginManagementView.swift
//  hdsup
//
//  UI for managing plugins
//

import SwiftUI

struct PluginManagementView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingAddPlugin = false
    @State private var newPluginURL = ""
    @State private var discoveredPlugins: [PluginManifest] = []
    @State private var isDiscovering = false
    @State private var discoveryError: String?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Configured Plugins") {
                    if appModel.pluginManager.plugins.isEmpty {
                        Text("No plugins configured")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appModel.pluginManager.plugins) { plugin in
                            PluginRow(plugin: plugin)
                        }
                    }
                }
                
                Section {
                    Button {
                        showingAddPlugin = true
                    } label: {
                        Label("Add Plugin", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Plugin Manager")
            .sheet(isPresented: $showingAddPlugin) {
                AddPluginView(
                    newPluginURL: $newPluginURL,
                    discoveredPlugins: $discoveredPlugins,
                    isDiscovering: $isDiscovering,
                    discoveryError: $discoveryError
                )
            }
        }
    }
}

struct PluginRow: View {
    @Environment(AppModel.self) private var appModel
    let plugin: PluginConfiguration
    @State private var showingDetails = false
    
    var body: some View {
        HStack {
            Image(systemName: plugin.metadata.icon)
                .font(.title2)
                .foregroundStyle(plugin.enabled ? .blue : .secondary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.metadata.name)
                    .font(.headline)
                
                Text(plugin.metadata.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                if let lastFetched = plugin.lastFetchedAt {
                    Text("Updated \(lastFetched, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                if let error = plugin.lastError {
                    Text("Error: \(error)")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { plugin.enabled },
                set: { _ in appModel.pluginManager.togglePlugin(id: plugin.id) }
            ))
            .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            PluginDetailView(plugin: plugin)
        }
    }
}

struct AddPluginView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Binding var newPluginURL: String
    @Binding var discoveredPlugins: [PluginManifest]
    @Binding var isDiscovering: Bool
    @Binding var discoveryError: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plugin Endpoint URL")
                        .font(.headline)
                    
                    TextField("https://api.example.com", text: $newPluginURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .textContentType(.URL)
                    
                    Text("Enter the base URL of your plugin server. The app will discover available plugins automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Button {
                    Task {
                        await discoverPlugins()
                    }
                } label: {
                    if isDiscovering {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Discover Plugins")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(newPluginURL.isEmpty || isDiscovering)
                
                if let error = discoveryError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding()
                }
                
                if !discoveredPlugins.isEmpty {
                    List(discoveredPlugins, id: \.endpoint) { manifest in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: manifest.metadata.icon)
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(manifest.metadata.name)
                                        .font(.headline)
                                    Text(manifest.metadata.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    appModel.pluginManager.addPlugin(manifest: manifest, baseURL: newPluginURL)
                                    dismiss()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Plugin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func discoverPlugins() async {
        isDiscovering = true
        discoveryError = nil
        discoveredPlugins = []
        
        do {
            let plugins = try await appModel.pluginManager.discoverPlugins(at: newPluginURL)
            discoveredPlugins = plugins
        } catch {
            discoveryError = error.localizedDescription
        }
        
        isDiscovering = false
    }
}

struct PluginDetailView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    let plugin: PluginConfiguration
    
    @State private var showingAuthConfig = false
    @State private var apiKey = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Plugin Information") {
                    LabeledContent("Name", value: plugin.metadata.name)
                    LabeledContent("Version", value: plugin.metadata.version)
                    LabeledContent("Author", value: plugin.metadata.author)
                    LabeledContent("ID", value: plugin.metadata.id)
                }
                
                Section("Configuration") {
                    LabeledContent("Endpoint", value: plugin.endpoint)
                    LabeledContent("Refresh Interval", value: "\(plugin.metadata.refreshInterval)s")
                    
                    Toggle("Enabled", isOn: Binding(
                        get: { plugin.enabled },
                        set: { _ in appModel.pluginManager.togglePlugin(id: plugin.id) }
                    ))
                }
                
                Section("Authentication") {
                    if plugin.authConfig != nil {
                        Label("Configured", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Not configured", systemImage: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                    }
                    
                    Button("Configure Authentication") {
                        showingAuthConfig = true
                    }
                }
                
                Section("Status") {
                    if let lastFetched = plugin.lastFetchedAt {
                        LabeledContent("Last Updated", value: lastFetched, format: .dateTime)
                    }
                    
                    if let error = plugin.lastError {
                        VStack(alignment: .leading) {
                            Text("Last Error")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                Section {
                    if let data = appModel.pluginManager.pluginData[plugin.id] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Latest Data")
                                .font(.headline)
                            
                            Text("Value: \(data.data.value.stringValue)")
                            
                            if let metrics = data.data.metrics {
                                ForEach(Array(metrics.keys.sorted()), id: \.self) { key in
                                    Text("\(key): \(metrics[key]?.stringValue ?? "N/A")")
                                        .font(.caption)
                                }
                            }
                        }
                    } else {
                        Text("No data available")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        appModel.pluginManager.removePlugin(id: plugin.id)
                        dismiss()
                    } label: {
                        Label("Remove Plugin", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Plugin Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAuthConfig) {
                AuthConfigView(plugin: plugin, apiKey: $apiKey)
            }
        }
    }
}

struct AuthConfigView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    let plugin: PluginConfiguration
    @Binding var apiKey: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section("API Key Authentication") {
                    SecureField("API Key", text: $apiKey)
                    
                    Button("Save") {
                        let authConfig = PluginAuthConfig(
                            type: "apikey",
                            apiKey: apiKey,
                            bearerToken: nil,
                            oauth2Token: nil
                        )
                        appModel.pluginManager.updatePluginAuth(id: plugin.id, authConfig: authConfig)
                        dismiss()
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
            .navigationTitle("Configure Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PluginManagementView()
        .environment(AppModel())
}
