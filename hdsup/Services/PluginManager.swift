//
//  PluginManager.swift
//  hdsup
//
//  Plugin discovery, loading, and management system
//

import Foundation
import Observation

@MainActor
@Observable
class PluginManager {
    /// Currently configured plugins
    var plugins: [PluginConfiguration] = []
    
    /// Plugin discovery state
    var isDiscovering = false
    var discoveryError: String?
    
    /// Data fetching state
    var isFetching = false
    var fetchErrors: [UUID: String] = [:]
    
    /// Latest plugin data
    var pluginData: [UUID: PluginAPIResponse] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let pluginsKey = "configured_plugins"
    
    init() {
        loadPlugins()
    }
    
    // MARK: - Plugin Discovery
    
    /// Discover plugins at a given endpoint
    func discoverPlugins(at baseURL: String) async throws -> [PluginManifest] {
        isDiscovering = true
        discoveryError = nil
        
        defer {
            isDiscovering = false
        }
        
        // Construct discovery endpoint (standard: /plugins/discover)
        guard var url = URL(string: baseURL) else {
            throw PluginManagerError.invalidURL
        }
        
        // Add discovery path if not already present
        if !url.path.hasSuffix("/plugins/discover") {
            url = url.appendingPathComponent("plugins/discover")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HUDApp/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PluginManagerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PluginManagerError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let discoveryResponse = try decoder.decode(PluginDiscoveryResponse.self, from: data)
        
        // Validate API version compatibility
        if !isCompatibleAPIVersion(discoveryResponse.apiVersion) {
            throw PluginManagerError.incompatibleAPIVersion(discoveryResponse.apiVersion)
        }
        
        return discoveryResponse.plugins
    }
    
    /// Add a plugin from manifest
    func addPlugin(manifest: PluginManifest, baseURL: String) {
        let endpoint = baseURL.hasSuffix("/") ? baseURL + manifest.endpoint : baseURL + "/" + manifest.endpoint
        
        let config = PluginConfiguration(
            id: UUID(),
            endpoint: endpoint,
            metadata: manifest.metadata,
            enabled: true,
            customRefreshInterval: nil,
            authConfig: nil,
            parameters: nil,
            displayPreferences: nil,
            lastFetchedAt: nil,
            lastError: nil
        )
        
        plugins.append(config)
        savePlugins()
    }
    
    // MARK: - Plugin Data Fetching
    
    /// Fetch data from a specific plugin
    func fetchPluginData(plugin: PluginConfiguration) async throws -> PluginAPIResponse {
        var url = URL(string: plugin.endpoint)!
        
        // Add query parameters if configured
        if let parameters = plugin.parameters, !parameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components.url!
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HUDApp/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add authentication if configured
        if let authConfig = plugin.authConfig {
            switch authConfig.type {
            case "apikey":
                if let apiKey = authConfig.apiKey {
                    request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
                }
            case "bearer":
                if let token = authConfig.bearerToken {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
            case "oauth2":
                if let oauth2Token = authConfig.oauth2Token {
                    request.setValue("Bearer \(oauth2Token.accessToken)", forHTTPHeaderField: "Authorization")
                }
            default:
                break
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PluginManagerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PluginManagerError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(PluginAPIResponse.self, from: data)
        
        // Validate API version
        if !isCompatibleAPIVersion(apiResponse.apiVersion) {
            throw PluginManagerError.incompatibleAPIVersion(apiResponse.apiVersion)
        }
        
        return apiResponse
    }
    
    /// Fetch data from all enabled plugins
    func fetchAllPluginData() async {
        isFetching = true
        fetchErrors.removeAll()
        
        await withTaskGroup(of: (UUID, Result<PluginAPIResponse, Error>).self) { group in
            for plugin in plugins where plugin.enabled {
                group.addTask {
                    do {
                        let response = try await self.fetchPluginData(plugin: plugin)
                        return (plugin.id, .success(response))
                    } catch {
                        return (plugin.id, .failure(error))
                    }
                }
            }
            
            for await (pluginId, result) in group {
                switch result {
                case .success(let response):
                    pluginData[pluginId] = response
                    if let index = plugins.firstIndex(where: { $0.id == pluginId }) {
                        plugins[index].lastFetchedAt = Date()
                        plugins[index].lastError = nil
                    }
                case .failure(let error):
                    fetchErrors[pluginId] = error.localizedDescription
                    if let index = plugins.firstIndex(where: { $0.id == pluginId }) {
                        plugins[index].lastError = error.localizedDescription
                    }
                }
            }
        }
        
        savePlugins()
        isFetching = false
    }
    
    // MARK: - Plugin Management
    
    func removePlugin(id: UUID) {
        plugins.removeAll { $0.id == id }
        pluginData.removeValue(forKey: id)
        fetchErrors.removeValue(forKey: id)
        savePlugins()
    }
    
    func togglePlugin(id: UUID) {
        if let index = plugins.firstIndex(where: { $0.id == id }) {
            plugins[index].enabled.toggle()
            savePlugins()
        }
    }
    
    func updatePluginAuth(id: UUID, authConfig: PluginAuthConfig) {
        if let index = plugins.firstIndex(where: { $0.id == id }) {
            plugins[index].authConfig = authConfig
            savePlugins()
        }
    }
    
    func updatePluginParameters(id: UUID, parameters: [String: String]) {
        if let index = plugins.firstIndex(where: { $0.id == id }) {
            plugins[index].parameters = parameters
            savePlugins()
        }
    }
    
    // MARK: - Persistence
    
    private func savePlugins() {
        if let encoded = try? JSONEncoder().encode(plugins) {
            userDefaults.set(encoded, forKey: pluginsKey)
        }
    }
    
    private func loadPlugins() {
        if let data = userDefaults.data(forKey: pluginsKey),
           let decoded = try? JSONDecoder().decode([PluginConfiguration].self, from: data) {
            plugins = decoded
        }
    }
    
    // MARK: - Utilities
    
    private func isCompatibleAPIVersion(_ version: String) -> Bool {
        // For now, accept version 1.x
        return version.hasPrefix("1.")
    }
    
    /// Convert plugin data to HUDData format
    func convertToHUDData(pluginId: UUID) -> HUDData? {
        guard let response = pluginData[pluginId] else { return nil }
        
        let value = response.data.value.stringValue
        let unit = response.data.metrics?["unit"]?.stringValue
        
        var metadata = response.data.metadata ?? [:]
        metadata["plugin"] = response.plugin.name
        metadata["version"] = response.plugin.version
        
        return HUDData(
            title: response.plugin.name,
            value: value,
            unit: unit,
            timestamp: ISO8601DateFormatter().date(from: response.timestamp) ?? Date(),
            metadata: metadata
        )
    }
}

// MARK: - Errors

enum PluginManagerError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case incompatibleAPIVersion(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid plugin URL"
        case .invalidResponse:
            return "Invalid response from plugin"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .incompatibleAPIVersion(let version):
            return "Incompatible API version: \(version)"
        }
    }
}
