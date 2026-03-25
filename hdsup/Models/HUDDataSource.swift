//
//  HUDDataSource.swift
//  hdsup
//
//  Data models for external data sources
//

import Foundation

// Protocol for any external data source
protocol HUDDataSource {
    var id: UUID { get }
    var name: String { get }
    var iconName: String { get }
    func fetchData() async throws -> HUDData
}

// Generic data container
struct HUDData: Codable, Identifiable {
    let id: UUID
    let title: String
    let value: String
    let unit: String?
    let timestamp: Date
    let metadata: [String: String]?
    
    init(id: UUID = UUID(), title: String, value: String, unit: String? = nil, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.id = id
        self.title = title
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// Example: Weather data source
struct WeatherDataSource: HUDDataSource {
    let id = UUID()
    let name = "Weather"
    let iconName = "cloud.sun.fill"
    let apiEndpoint: String
    
    func fetchData() async throws -> HUDData {
        // Example API call - replace with your actual endpoint
        guard let url = URL(string: apiEndpoint) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
        
        return HUDData(
            title: "Temperature",
            value: "\(weatherResponse.temperature)",
            unit: "°C",
            metadata: ["condition": weatherResponse.condition]
        )
    }
    
    struct WeatherResponse: Codable {
        let temperature: Double
        let condition: String
    }
}

// Example: System metrics data source
struct SystemMetricsDataSource: HUDDataSource {
    let id = UUID()
    let name = "System Metrics"
    let iconName = "cpu"
    
    func fetchData() async throws -> HUDData {
        // Example: Get system info (you'd use actual system APIs here)
        let processInfo = ProcessInfo.processInfo
        
        return HUDData(
            title: "Memory",
            value: String(format: "%.1f", Double(processInfo.physicalMemory) / 1_073_741_824),
            unit: "GB",
            metadata: ["cores": "\(processInfo.processorCount)"]
        )
    }
}

// Example: Custom API data source
struct CustomAPIDataSource: HUDDataSource {
    let id = UUID()
    let name: String
    let iconName: String
    let endpoint: String
    
    func fetchData() async throws -> HUDData {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: String].self, from: data)
        
        return HUDData(
            title: name,
            value: response["value"] ?? "N/A",
            unit: response["unit"],
            metadata: response
        )
    }
}
