//
//  HUDDataService.swift
//  hdsup
//
//  Service for managing HUD data sources and updates
//

import Foundation
import Observation

@MainActor
@Observable
class HUDDataService {
    var dataSources: [any HUDDataSource] = []
    var currentData: [UUID: HUDData] = [:]
    var isUpdating: Bool = false
    var lastError: Error?
    
    private var updateTask: Task<Void, Never>?
    
    init() {
        // Initialize with example data sources
        setupExampleDataSources()
    }
    
    func setupExampleDataSources() {
        // Add system metrics
        dataSources.append(SystemMetricsDataSource())
        
        // Add example custom API sources
        // Replace these with your actual endpoints
        dataSources.append(CustomAPIDataSource(
            name: "Server Status",
            iconName: "server.rack",
            endpoint: "https://api.example.com/status"
        ))
    }
    
    func addDataSource(_ source: any HUDDataSource) {
        dataSources.append(source)
    }
    
    func removeDataSource(id: UUID) {
        dataSources.removeAll { $0.id == id }
        currentData.removeValue(forKey: id)
    }
    
    func startAutoUpdate(interval: TimeInterval = 30) {
        stopAutoUpdate()
        
        updateTask = Task {
            while !Task.isCancelled {
                await updateAllData()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
    
    func stopAutoUpdate() {
        updateTask?.cancel()
        updateTask = nil
    }
    
    func updateAllData() async {
        isUpdating = true
        lastError = nil
        
        await withTaskGroup(of: (UUID, Result<HUDData, Error>).self) { group in
            for source in dataSources {
                group.addTask {
                    do {
                        let data = try await source.fetchData()
                        return (source.id, .success(data))
                    } catch {
                        return (source.id, .failure(error))
                    }
                }
            }
            
            for await (id, result) in group {
                switch result {
                case .success(let data):
                    currentData[id] = data
                case .failure(let error):
                    lastError = error
                    print("Error fetching data for source \(id): \(error)")
                }
            }
        }
        
        isUpdating = false
    }
    
    func getData(for sourceId: UUID) -> HUDData? {
        return currentData[sourceId]
    }
    

}
